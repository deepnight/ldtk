package display;

class WorldRender extends dn.Process {
	public var editor(get,never) : Editor; inline function get_editor() return Editor.ME;
	public var camera(get,never) : display.Camera; inline function get_camera() return Editor.ME.camera;
	public var settings(get,never) : AppSettings; inline function get_settings() return App.ME.settings;

	var worldLevels : Map<Int, { bounds:h2d.Graphics, render:h2d.Object }> = new Map();
	var worldBg : { wrapper:h2d.Object, col:h2d.Bitmap, tex:dn.heaps.TiledTexture };
	public var worldWrapper : h2d.Layers;
	var bounds : h2d.Graphics;
	var boundsGlow : h2d.Graphics;
	var grid : h2d.Graphics;
	var rectBleeps : Array<h2d.Object> = [];

	var levelInvalidations : Map<Int,Bool> = new Map();


	public function new() {
		super(editor);

		editor.ge.addGlobalListener(onGlobalEvent);
		createRootInLayers(editor.root, Const.DP_MAIN);

		var w = new h2d.Object();
		worldBg = {
			wrapper : w,
			col: new h2d.Bitmap(w),
			tex: new dn.heaps.TiledTexture(Assets.elements.getTile("largeStripes"), 1, 1, w),
		}
		worldBg.tex.alpha = 0.5;
		editor.root.add(worldBg.wrapper, Const.DP_MAIN);
		editor.root.under(worldBg.wrapper);
		worldBg.wrapper.alpha = 0;

		worldWrapper = new h2d.Layers();
		root.add(worldWrapper, Const.DP_MAIN);
	}

	override function onDispose() {
		super.onDispose();
		worldBg.wrapper.remove();
		editor.ge.removeListener(onGlobalEvent);
	}

	override function onResize() {
		super.onResize();
		renderBg();
	}

	function onGlobalEvent(e:GlobalEvent) {
		switch e {
			case WorldMode(active):
				updateWorld();

			case ViewportChanged:
				root.setScale( camera.adjustedZoom );
				root.x = M.round( editor.canvasWid()*0.5 - camera.worldX * camera.adjustedZoom );
				root.y = M.round( editor.canvasHei()*0.5 - camera.worldY * camera.adjustedZoom );

			case ProjectSelected:
				resetWorldRender();
				updateWorld();

			case ProjectSettingsChanged:
				resetWorldRender();
				renderBg();

			case LevelRestoredFromHistory(l):
				invalidateWorldLevel(l);

			case LevelSelected(l):
				updateWorld();

			case LevelResized(l):
				invalidateWorldLevel(l);

			case LevelSettingsChanged(l):
				invalidateWorldLevel(l);

			case LayerDefRemoved(uid):
				resetWorldRender();

			case LayerDefSorted:
				resetWorldRender();

			case LayerDefChanged, LayerDefConverted:
				resetWorldRender();

			case TilesetDefPixelDataCacheRebuilt(td):
				resetWorldRender();

			case LevelAdded(l):
				updateWorld();

			case LevelRemoved(l):
				removeWorldLevel(l);
				updateWorld();

			case LevelSorted:
				// TODO render here instead of from worldTool ?

			case _:
		}
	}

	public inline function invalidateWorldLevel(l:data.Level) {
		levelInvalidations.set(l.uid, true);
	}

	public function resetWorldRender() {
		App.LOG.render("Reset world render");
		for(e in worldLevels) {
			e.bounds.remove();
			e.render.remove();
		}
		worldLevels = new Map();
		worldWrapper.removeChildren();

		// World origin axes
		var origin = new h2d.Graphics(worldWrapper);
		origin.lineStyle(3, 0x0, 0.3);
		var size = 2048;
		origin.moveTo(0, -size*0.5);
		origin.lineTo(0, size*0.5);
		origin.moveTo(-size*0.5, 0);
		origin.lineTo(size*0.5, 0);

		for(l in editor.project.levels)
			invalidateWorldLevel(l);
	}

	function renderBg() {
		worldBg.tex.resize( Std.int(editor.canvasWid()), Std.int(editor.canvasHei()) );
		worldBg.col.tile = h2d.Tile.fromColor( C.interpolateInt(editor.project.bgColor, 0x8187bd, 0.85) );
		worldBg.col.scaleX = editor.canvasWid();
		worldBg.col.scaleY = editor.canvasHei();
	}

	public function updateWorld() {
		var cur = editor.curLevel;
		for( l in editor.project.levels )
			if( worldLevels.exists(l.uid) ) {
				var e = worldLevels.get(l.uid);

				if( l.uid==editor.curLevelId && !editor.worldMode ) {
					// Hide current level in editor mode
					e.bounds.visible = false;
					e.render.visible = false;
				}
				else if( editor.worldMode ) {
					// Show everything in world mode
					e.render.visible = true;
					e.render.alpha = 1;
					e.bounds.alpha = 1;
				}
				else {
					// Fade other levels in editor mode
					var dist = M.fmax(
						M.fmax(0, cur.worldX - (l.worldX+l.pxWid)) + M.fmax( 0, l.worldX - (cur.worldX+cur.pxWid) ),
						M.fmax(0, cur.worldY - (l.worldY+l.pxHei)) + M.fmax( 0, l.worldY - (cur.worldY+cur.pxHei) )
					);
					e.bounds.alpha = 0.33;
					e.render.alpha = 0.33;
					e.render.visible = dist<=100;
				}

				// Position
				e.render.setPosition( l.worldX, l.worldY );
				e.bounds.setPosition( l.worldX, l.worldY );
			}

	}

	function removeWorldLevel(l:data.Level) {
		if( worldLevels.exists(l.uid) ) {
			worldLevels.get(l.uid).render.remove();
			worldLevels.get(l.uid).bounds.remove();
			worldLevels.remove(l.uid);
		}
	}

	function renderWorldLevel(l:data.Level) {
		if( l==null )
			throw "Unknown level";

		App.LOG.render("Rendered WorldLevel "+l);

		// Cleanup
		levelInvalidations.remove(l.uid);
		if( worldLevels.exists(l.uid) ) {
			worldLevels.get(l.uid).render.remove();
			worldLevels.get(l.uid).bounds.remove();
		}

		// Init
		var wl = {
			render : new h2d.Object(),
			bounds : new h2d.Graphics()
		}
		worldWrapper.add(wl.render, 0);
		worldWrapper.add(wl.bounds, 1);
		worldLevels.set(l.uid, wl);

		// Per-coord limit
		var doneCoords = new Map();
		inline function markCoordAsDone(li:data.inst.LayerInstance, cx:Int, cy:Int) {
			if( !doneCoords.exists(li.def.gridSize) )
				doneCoords.set(li.def.gridSize, new Map());
			doneCoords.get(li.def.gridSize).set( li.coordId(cx,cy), true);
		}
		inline function isCoordDone(li:data.inst.LayerInstance, cx:Int, cy:Int) {
			return doneCoords.exists(li.def.gridSize) && doneCoords.get(li.def.gridSize).exists( li.coordId(cx,cy) );
		}

		// Render world level
		for(li in l.layerInstances) {
			if( li.def.type==Entities )
				continue;

			// if( li.def.isAutoLayer() && li.autoTilesCache!=null ) {
			// 	// Auto layer
			// 	var source = li.def.type==IntGrid ? li : l.getLayerInstance(li.def.autoSourceLayerDefUid);
			// 	var td = editor.project.defs.getTilesetDef(li.def.autoTilesetDefUid);
			// 	var doneCoords = new Map();
			// 	li.def.iterateActiveRulesInDisplayOrder( (r)->{
			// 		if( li.autoTilesCache.exists( r.uid ) ) {
			// 			for( coordId in li.autoTilesCache.get( r.uid ).keys() ) {
			// 				if( doneCoords.exists(coordId) )
			// 					continue;

			// 				for( t in li.autoTilesCache.get( r.uid ).get(coordId) ) {
			// 					if( td.isTileOpaque(t.tid) ) {
			// 						var c = td.getAverageTileColor(t.tid);
			// 						render.beginFill( C.removeAlpha(c), 1 );
			// 						render.drawRect(t.x*scale, t.y*scale, td.tileGridSize*scale, td.tileGridSize*scale);
			// 						doneCoords.set(coordId,true);
			// 						break;
			// 					}
			// 				}
			// 			}
			// 		}
			// 	});
			// }
			if( li.def.type==IntGrid ) {
				// Pure intGrid
				var pixelGrid = new dn.heaps.PixelGrid(li.def.gridSize, li.cWid, li.cHei, wl.render);
				for(cy in 0...li.cHei)
				for(cx in 0...li.cWid) {
					if( !isCoordDone(li,cx,cy) && li.hasAnyGridValue(cx,cy) ) {
						markCoordAsDone(li, cx,cy);
						pixelGrid.setPixel(cx,cy, li.getIntGridColorAt(cx,cy) );
					}
				}
			}
			else if( li.def.type==Tiles ) {
				// Classic tiles
				var pixelGrid = new dn.heaps.PixelGrid(li.def.gridSize, li.cWid, li.cHei, wl.render);
				var td = editor.project.defs.getTilesetDef(li.def.tilesetDefUid);
				for(cy in 0...li.cHei)
				for(cx in 0...li.cWid)
					if( !isCoordDone(li,cx,cy) && li.hasAnyGridTile(cx,cy) ) {
						markCoordAsDone(li, cx,cy);
						pixelGrid.setPixel(cx,cy, td.getAverageTileColor( li.getTopMostGridTile(cx,cy).tileId ) );
					}
			}
		}

		// Bounds
		wl.bounds.lineStyle(3, l==editor.curLevel ? 0xffffff : 0xffcc00, 1);
		wl.bounds.drawRect(0, 0, l.pxWid, l.pxHei);

		// Identifier
		var bg = new h2d.ScaleGrid(Assets.elements.getTile("fieldBg"), 2, 2, wl.bounds );
		bg.color.setColor( C.addAlphaF(0x464e79) );
		bg.alpha = 0.8;

		var tf = new h2d.Text(Assets.fontPixel, bg);
		tf.text = l.identifier;
		tf.textColor = 0xffcc00;
		tf.x = 4;

		bg.setScale(2);
		bg.width = tf.x*2 + tf.textWidth;
		bg.height = tf.textHeight;
		bg.x = Std.int( l.pxWid*0.5 - bg.width*bg.scaleX*0.5 );
		bg.y = 8;
	}


	override function postUpdate() {
		super.postUpdate();

		// World
		worldBg.wrapper.alpha += ( ( editor.worldMode ? 0.3 : 0 ) - worldBg.wrapper.alpha ) * 0.1;
		worldBg.wrapper.visible = worldBg.wrapper.alpha>=0.02;

		// World levels invalidation (max one per frame)
		for( uid in levelInvalidations.keys() ) {
			renderWorldLevel( editor.project.getLevel(uid) );
			updateWorld();
			break;
		}
	}

}
