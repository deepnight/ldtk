package display;

class LayerRender {
	var editor(get,never) : Editor; inline function get_editor() return Editor.ME;

	public var root : h2d.Object;
	var li : data.inst.LayerInstance;
	var entityRenders : Array<EntityRender> = [];

	/** Need to call render() again after setting this **/
	public var renderAutoLayers : Bool;


	public function new(li:data.inst.LayerInstance, ?renderAutoLayers=true, ?target:h2d.Object) {
		root = new h2d.Object(target);
		this.renderAutoLayers = renderAutoLayers;
		this.li = li;
		render();
	}

	public function dispose() {
		clear();

		root.remove();
		root = null;

		li = null;
		entityRenders = null;
	}


	public function render() {
		clear();

		// Apply offsets
		root.x = li.pxTotalOffsetX; // TODO apply to layer objects instead
		root.y = li.pxTotalOffsetY;

		// Render
		switch li.def.type {
		case IntGrid, AutoLayer:
			if( li.def.isAutoLayer() && li.def.autoTilesetDefUid!=null && renderAutoLayers ) {
				// Auto-layer tiles
				var td = editor.project.defs.getTilesetDef( li.def.autoTilesetDefUid );
				var tg = new h2d.TileGroup( td.getAtlasTile(), root);

				if( li.autoTilesCache==null )
					li.applyAllAutoLayerRules();

				li.def.iterateActiveRulesInDisplayOrder( (r)-> {
					if( li.autoTilesCache.exists( r.uid ) ) {
						for(coordId in li.autoTilesCache.get( r.uid ).keys()) {
							// doneCoords.set(coordId, true);
							for(tileInfos in li.autoTilesCache.get( r.uid ).get(coordId)) {
								tg.addTransform(
									tileInfos.x + ( ( dn.M.hasBit(tileInfos.flips,0)?1:0 ) + li.def.tilePivotX ) * li.def.gridSize,
									tileInfos.y + ( ( dn.M.hasBit(tileInfos.flips,1)?1:0 ) + li.def.tilePivotY ) * li.def.gridSize,
									dn.M.hasBit(tileInfos.flips,0)?-1:1,
									dn.M.hasBit(tileInfos.flips,1)?-1:1,
									0,
									td.extractTile(tileInfos.srcX, tileInfos.srcY)
								);
							}
						}
					}
				});
			}
			else if( li.def.type==IntGrid ) {
				// Normal intGrid
				var pixelGrid = new dn.heaps.PixelGrid(li.def.gridSize, li.cWid, li.cHei, root);

				for(cy in 0...li.cHei)
				for(cx in 0...li.cWid)
					if( li.hasIntGrid(cx,cy) )
						pixelGrid.setPixel( cx, cy, li.getIntGridColorAt(cx,cy) );
			}

		case Entities:
			clear();
			for(ei in li.entityInstances)
				entityRenders.push( new EntityRender(ei, li.def, root) );

		case Tiles:
			var td = editor.project.defs.getTilesetDef(li.def.tilesetDefUid);
			if( td!=null && td.isAtlasLoaded() ) {
				var tg = new h2d.TileGroup( td.getAtlasTile(), root );

				for(cy in 0...li.cHei)
				for(cx in 0...li.cWid) {
					if( !li.hasAnyGridTile(cx,cy) )
						continue;

					for( tileInf in li.getGridTileStack(cx,cy) ) {
						var t = td.getTile(tileInf.tileId);
						t.setCenterRatio(li.def.tilePivotX, li.def.tilePivotY);
						var sx = M.hasBit(tileInf.flips, 0) ? -1 : 1;
						var sy = M.hasBit(tileInf.flips, 1) ? -1 : 1;
						tg.addTransform(
							(cx + li.def.tilePivotX + (sx<0?1:0)) * li.def.gridSize,
							(cy + li.def.tilePivotX + (sy<0?1:0)) * li.def.gridSize,
							sx,
							sy,
							0,
							t
						);
					}
				}
			}
			else {
				// Missing tileset
				var tileError = data.def.TilesetDef.makeErrorTile(li.def.gridSize);
				var tg = new h2d.TileGroup( tileError, root );
				for(cy in 0...li.cHei)
				for(cx in 0...li.cWid)
					if( li.hasAnyGridTile(cx,cy) )
						tg.add(
							(cx + li.def.tilePivotX) * li.def.gridSize,
							(cy + li.def.tilePivotX) * li.def.gridSize,
							tileError
						);
			}
		}
	}

	public function clear() {
		for(er in entityRenders)
			er.destroy();
		entityRenders = [];

		root.removeChildren();
	}

}