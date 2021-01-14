package display;

class LayerRender {
	var editor(get,never) : Editor; inline function get_editor() return Editor.ME;

	public var root(default,null) : Null<h2d.Object>;
	var entityRenders : Array<EntityRender> = [];


	public function new() {}


	public function dispose() {
		clear();

		root.remove();
		root = null;

		entityRenders = null;
	}


	public function render(li:data.inst.LayerInstance, renderAutoLayers=true, ?target:h2d.Object) {
		// Cleanup
		if( root!=null )
			clear();

		// Init root
		if( root==null )
			root = new h2d.Object(target);
		else if( target!=null && root.parent!=target )
			target.addChild(root);

		switch li.def.type {
		case IntGrid, AutoLayer:
			var td = editor.project.defs.getTilesetDef( li.def.autoTilesetDefUid );

			if( li.def.isAutoLayer() && renderAutoLayers && td!=null && td.isAtlasLoaded() ) {
				// Auto-layer tiles
				var tg = new h2d.TileGroup( td.getAtlasTile(), root);

				if( li.autoTilesCache==null )
					li.applyAllAutoLayerRules();

				li.def.iterateActiveRulesInDisplayOrder( (r)-> {
					if( li.autoTilesCache.exists( r.uid ) ) {
						for(coordId in li.autoTilesCache.get( r.uid ).keys())
						for(tileInfos in li.autoTilesCache.get( r.uid ).get(coordId)) {
							tg.addTransform(
								tileInfos.x + ( ( dn.M.hasBit(tileInfos.flips,0)?1:0 ) + li.def.tilePivotX ) * li.def.gridSize + li.pxTotalOffsetX,
								tileInfos.y + ( ( dn.M.hasBit(tileInfos.flips,1)?1:0 ) + li.def.tilePivotY ) * li.def.gridSize + li.pxTotalOffsetY,
								dn.M.hasBit(tileInfos.flips,0)?-1:1,
								dn.M.hasBit(tileInfos.flips,1)?-1:1,
								0,
								td.extractTile(tileInfos.srcX, tileInfos.srcY)
							);
						}
					}
				});
			}
			else if( li.def.type==IntGrid ) {
				// Normal intGrid
				var pixelGrid = new dn.heaps.PixelGrid(li.def.gridSize, li.cWid, li.cHei, root);
				pixelGrid.x = li.pxTotalOffsetX;
				pixelGrid.y = li.pxTotalOffsetY;

				for(cy in 0...li.cHei)
				for(cx in 0...li.cWid)
					if( li.hasIntGrid(cx,cy) )
						pixelGrid.setPixel( cx, cy, li.getIntGridColorAt(cx,cy) );
			}


		case Entities:
			// Entity layer
			for(ei in li.entityInstances)
				entityRenders.push( new EntityRender(ei, li.def, root) );


		case Tiles:
			// Classic tiles layer
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
							(cx + li.def.tilePivotX + (sx<0?1:0)) * li.def.gridSize + li.pxTotalOffsetX,
							(cy + li.def.tilePivotX + (sy<0?1:0)) * li.def.gridSize + li.pxTotalOffsetY,
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


	// var flippedTileCache : Map< Int, Map<Int,hxd.BitmapData> >;

	// function getFlippedPixels(td:data.def.TilesetDef, tid:Int, flipBits:Int) : hxd.BitmapData {
	// 	if( flippedTileCache==null )
	// 		flippedTileCache = new Map();

	// 	if( !flippedTileCache.exists(tid) )
	// 		flippedTileCache.set(tid, new Map());

	// 	if( !flippedTileCache.get(tid).exists(flipBits) ) {
	// 		// Init cache
	// 		var size = td.tileGridSize;
	// 		var p = hxd.Pixels.alloc(size, size, td.pixels.format);
	// 		var srcX = td.getTileSourceX(tid);
	// 		var srcY = td.getTileSourceY(tid);
	// 		switch flipBits {
	// 			case 1:
	// 				for( x in 0...size )
	// 					p.blit(
	// 						size-1-x, 0,
	// 						td.pixels,
	// 						srcX+x, srcY,
	// 						1, size
	// 					);

	// 			case 2: throw "not done yet"; // TODO
	// 			case 3: throw "not done yet"; // TODO

	// 			case _: throw "unexpected flipbits value";
	// 		}
	// 		var bd = new hxd.BitmapData(p.width, p.height);
	// 		bd.setPixels(p);
	// 		flippedTileCache.get(tid).set(flipBits, bd);
	// 		trace("init for #"+tid+" flips="+flipBits);
	// 	}

	// 	return flippedTileCache.get(tid).get(flipBits);
	// }

	public function createPng(p:data.Project, l:data.Level, li:data.inst.LayerInstance) : Null<haxe.io.Bytes> {
		switch li.def.type {
			case IntGrid, Tiles, AutoLayer:
				render(li);
				var tex = new h3d.mat.Texture(l.pxWid, l.pxHei, [Target]);
				root.drawTo(tex);
				return tex.capturePixels().toPNG();

			case Entities:
				return null;
		}
	}

	public function clear() {
		for(er in entityRenders)
			er.destroy();
		entityRenders = [];

		root.removeChildren();
	}

}