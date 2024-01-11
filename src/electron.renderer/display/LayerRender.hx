package display;

class LayerRender {
	var editor(get,never) : Editor; inline function get_editor() return Editor.ME;

	public var root(default,null) : Null<h2d.Object>;
	var mask : Null<h2d.Mask>;
	var entityRenders : Array<EntityRender> = [];

	var lastLi : Null<data.inst.LayerInstance>;


	public function new() {}


	public function dispose() {
		clear();

		if( mask!=null ) {
			mask.remove();
			mask = null;
		}

		root.remove();
		root = null;


		entityRenders = null;
	}

	public function onGlobalEvent(ev:GlobalEvent) {
		for(er in entityRenders)
			er.onGlobalEvent(ev);

		switch( ev ) {
			case ViewportChanged(zoomChanged):
				updateParallax();

			case LayerDefChanged(defUid, contentInvalidated):
				if( lastLi!=null && lastLi.layerDefUid==defUid )
					updateParallax();

			case _:
		}
	}


	function updateParallax() {
		if( lastLi==null )
			return;

		root.x = editor.camera.getParallaxOffsetX(lastLi);
		root.y = editor.camera.getParallaxOffsetY(lastLi);
		root.setScale( lastLi.def.getScale() );
	}


	static var _cachedIdentityVector = new h3d.Vector4(1,1,1,1);
	public static inline function renderAutoTileInfos(li:data.inst.LayerInstance, td:data.def.TilesetDef, tileInfos, tg:h2d.TileGroup) {
		_cachedIdentityVector.a = tileInfos.a;
		@:privateAccess tg.content.addTransform(
			tileInfos.x + ( ( dn.M.hasBit(tileInfos.flips,0)?1:0 ) + li.def.tilePivotX ) * li.def.gridSize + li.pxTotalOffsetX,
			tileInfos.y + ( ( dn.M.hasBit(tileInfos.flips,1)?1:0 ) + li.def.tilePivotY ) * li.def.gridSize + li.pxTotalOffsetY,
			dn.M.hasBit(tileInfos.flips,0)?-1:1,
			dn.M.hasBit(tileInfos.flips,1)?-1:1,
			0,
			_cachedIdentityVector,
			td.getOptimizedTileAt(tileInfos.srcX, tileInfos.srcY)
		);
	}


	public static inline function renderGridTile(li:data.inst.LayerInstance, td:data.def.TilesetDef, tileInf:data.DataTypes.GridTileInfos, cx:Int, cy:Int, tg:h2d.TileGroup) {
		var t = td.getTileById(tileInf.tileId);
		t.setCenterRatio(li.def.tilePivotX, li.def.tilePivotY);
		var sx = M.hasBit(tileInf.flips, 0) ? -1 : 1;
		var sy = M.hasBit(tileInf.flips, 1) ? -1 : 1;
		var tx = (cx + li.def.tilePivotX + (sx<0?1:0)) * li.def.gridSize + li.pxTotalOffsetX;
		var ty = (cy + li.def.tilePivotX + (sy<0?1:0)) * li.def.gridSize + li.pxTotalOffsetY;
		tg.addTransform(tx, ty, sx, sy, 0, t);
	}

	public function render(li:data.inst.LayerInstance, renderAutoLayers=true, ?target:h2d.Object) {
		// Cleanup
		if( root!=null )
			clear();
		lastLi = li;

		// Init root
		if( root==null )
			root = new h2d.Object(target);
		else if( target!=null && root.parent!=target )
			target.addChild(root);


		// Init mask
		switch li.def.type {
			case IntGrid, Tiles, AutoLayer:
				if( mask==null )
					mask = new h2d.Mask(li.pxWid, li.pxHei, root);

			case Entities:
				if( mask!=null ) {
					mask.remove();
					mask = null;
				}
		}
		if( mask!=null ) {
			mask.width = li.pxWid;
			mask.height = li.pxHei;
		}

		var renderTarget = mask!=null ? mask : root;

		switch li.def.type {
		case IntGrid, AutoLayer:
			var td = li.getTilesetDef();

			if( li.def.isAutoLayer() && renderAutoLayers && td!=null && td.isAtlasLoaded() ) {
				var ed = td.getTagsEnumDef();

				// Auto-layer tiles
				var pixelGrid = new dn.heaps.PixelGrid(li.def.gridSize, li.cWid, li.cHei, renderTarget);
				pixelGrid.x = li.pxTotalOffsetX;
				pixelGrid.y = li.pxTotalOffsetY;

				var tg = new h2d.TileGroup( td.getAtlasTile(), renderTarget);
				var gr = App.ME.settings.v.tileEnumOverlays ? new h2d.Graphics(renderTarget) : null;

				// If we're showing enums, dim the tileset slightly so the overlays stand out.
				if( App.ME.settings.v.tileEnumOverlays )
					tg.setDefaultColor(0xcccccc, .5);

				if( li.autoTilesCache==null )
					li.applyAllRules();

				li.def.iterateActiveRulesInDisplayOrder( li, (r)-> {
					if( li.autoTilesCache.exists( r.uid ) ) {
						var grid = li.def.gridSize;
						for(tilesArray in li.autoTilesCache.get( r.uid ))
						for(tileInfos in tilesArray) {
							// Tile
							renderAutoTileInfos(li, td, tileInfos, tg);

							if( App.ME.settings.v.tileEnumOverlays && ed!=null ) {
								var n = 0;
								for( ev in ed.values) {
									if( td.hasTag(ev.id, tileInfos.tid)) {
										gr.lineStyle(1, ev.color, 1);
										gr.drawRect(
											tileInfos.x + li.def.tilePivotX*li.def.gridSize + li.pxTotalOffsetX,
											tileInfos.y + li.def.tilePivotY*li.def.gridSize + li.pxTotalOffsetY,
											li.def.gridSize - 1 - n * 2,
											li.def.gridSize - 1 - n * 2
										);
										n++;
									}
								}
							}
						}
					}
				});
			}
			else if( li.def.type==IntGrid ) {
				// Normal intGrid
				var pixelGrid = new dn.heaps.PixelGrid(li.def.gridSize, li.cWid, li.cHei, renderTarget);
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
				entityRenders.push( new EntityRender(ei, li.def, renderTarget) );


		case Tiles:
			// Classic tiles layer
			var offX = 2;
			var offY = 2;
			var td = li.getTilesetDef();
			if( td!=null && td.isAtlasLoaded() ) {
				var ed = td.getTagsEnumDef();
				var tg = new h2d.TileGroup( td.getAtlasTile(), renderTarget );
				var gr = App.ME.settings.v.tileEnumOverlays ? new h2d.Graphics(renderTarget) : null;

				// If we're showing enums, dim the tileset slightly so the overlays stand out.
				if( App.ME.settings.v.tileEnumOverlays )
					tg.setDefaultColor(0xcccccc, .5);

				for(cy in 0...li.cHei)
				for(cx in 0...li.cWid) {
					if( !li.hasAnyGridTile(cx,cy) )
						continue;

					for( tileInf in li.getGridTileStack(cx,cy) ) {
						// Tile
						renderGridTile(li, td, tileInf, cx,cy, tg);

						if( App.ME.settings.v.tileEnumOverlays && ed!=null ) {
							var n = 0;
							for( ev in ed.values) {
								if( td.hasTag(ev.id, tileInf.tileId)) {
									gr.lineStyle(1, ev.color, 1);
									gr.drawRect(
										(cx + li.def.tilePivotX)*li.def.gridSize + li.pxTotalOffsetX  +  n + .5,
										(cy + li.def.tilePivotY)*li.def.gridSize + li.pxTotalOffsetY  +  n + .5,
										li.def.gridSize - 1 - n * 2,
										li.def.gridSize - 1 - n * 2
									);
									n++;
								}
							}
						}
					}
				}
			}
			else {
				// Missing tileset
				var tileError = data.def.TilesetDef.makeErrorTile(li.def.gridSize);
				var tg = new h2d.TileGroup( tileError, renderTarget );
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



	public function renderBgToTexture(l:data.Level, tex:h3d.mat.Texture) {
		tex.clear( l.getBgColor() );

		if( l.bgRelPath!=null ) {
			var bmp = l.createBgTiledTexture();
			if( bmp!=null )
				bmp.drawTo(tex);
		}
	}

	public function createBgPng(p:data.Project, l:data.Level) : Null<haxe.io.Bytes> {
		var tex = new h3d.mat.Texture(l.pxWid, l.pxHei, [Target]);
		renderBgToTexture(l, tex);
		return try tex.capturePixels().toPNG() catch(_) null;
	}


	/**
		Generate all PNGs for a single layer instance (auto-layer IntGrids generate both tiles & pixel images)
		Note: if `secondarySuffix` is null, then the output image is the "main" render of this layer.
	**/
	public function createPngs(p:data.Project, l:data.Level, li:data.inst.LayerInstance) : Array<{ secondarySuffix:Null<String>, bytes:haxe.io.Bytes, tex:Null<h3d.mat.Texture> }> {
		var out = [];
		switch li.def.type {
			case IntGrid, Tiles, AutoLayer:
				// Tiles
				if( li.def.isAutoLayer() || li.def.type==Tiles ) {
					render(li);
					var tex = new h3d.mat.Texture(l.pxWid, l.pxHei, [Target]);
					var wrapper = new h2d.Object();
					wrapper.addChild(root);
					root.alpha = li.def.displayOpacity; // apply layer alpha
					wrapper.drawTo(tex);
					var pixels = try tex.capturePixels() catch(_) null;
					out.push({
						secondarySuffix: null,
						bytes: pixels==null ? null : pixels.toPNG(),
						tex: tex,
					});
				}

				// Export IntGrid as pixel tiny image
				if( li.def.type==IntGrid ) {
					var pixels = hxd.Pixels.alloc(li.cWid, li.cHei, RGBA);
					for(cy in 0...li.cHei)
					for(cx in 0...li.cWid) {
						if( li.hasIntGrid(cx,cy) )
							pixels.setPixel( cx, cy, C.addAlphaF(li.getIntGridColorAt(cx,cy)) );
					}
					out.push({
						secondarySuffix: "int",
						bytes: pixels.toPNG(),
						tex: null,
					});
				}

			case Entities:
		}
		return out;
	}


	public function drawToTexture(tex:h3d.mat.Texture, p:data.Project, l:data.Level, li:data.inst.LayerInstance) : Bool {
		switch li.def.type {
		case IntGrid, Tiles, AutoLayer:
			if( li.def.isAutoLayer() || li.def.type==Tiles ) {
				// Tiles
				render(li);
				var wrapper = new h2d.Object();
				wrapper.addChild(root);
				root.alpha = li.def.displayOpacity; // apply layer alpha
				wrapper.drawTo(tex);
				return true;
			}
			else
				return false;

		case Entities:
			return false;
		}
	}


	public function clear() {
		for(er in entityRenders)
			er.destroy();
		entityRenders = [];

		root.removeChildren();
		mask = null;
	}

}
