package display;

typedef WorldLevelRender = {
	var bg: h2d.Bitmap;
	var bounds: h2d.Graphics;
	var render: h2d.Object;
	var label: h2d.ScaleGrid;
}

class WorldRender extends dn.Process {
	public var editor(get,never) : Editor; inline function get_editor() return Editor.ME;
	public var camera(get,never) : display.Camera; inline function get_camera() return Editor.ME.camera;
	public var settings(get,never) : AppSettings; inline function get_settings() return App.ME.settings;

	var levels : Map<Int,WorldLevelRender> = new Map();
	var worldBg : { wrapper:h2d.Object, col:h2d.Bitmap, tex:dn.heaps.TiledTexture };
	var worldBounds : h2d.Graphics;
	var axes : h2d.Graphics;
	public var levelsWrapper : h2d.Layers;

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
		editor.root.add(worldBg.wrapper, Const.DP_BG);
		worldBg.wrapper.alpha = 0;

		axes = new h2d.Graphics();
		editor.root.add(axes, Const.DP_BG);

		worldBounds = new h2d.Graphics();
		root.add(worldBounds, Const.DP_BG);

		levelsWrapper = new h2d.Layers();
		root.add(levelsWrapper, Const.DP_MAIN);
	}

	override function onDispose() {
		super.onDispose();
		worldBg.wrapper.remove();
		axes.remove();
		editor.ge.removeListener(onGlobalEvent);
	}

	override function onResize() {
		super.onResize();
		renderAxes();
		renderBg();
	}

	function onGlobalEvent(e:GlobalEvent) {
		switch e {
			case WorldMode(active):
				if( active )
					invalidateLevel(editor.curLevel);
				updateLayout();

			case ViewportChanged:
				root.setScale( camera.adjustedZoom );
				root.x = M.round( camera.width*0.5 - camera.worldX * camera.adjustedZoom );
				root.y = M.round( camera.height*0.5 - camera.worldY * camera.adjustedZoom );
				renderAxes();
				updateLabels();

			case WorldLevelMoved:
				updateLayout();

			case ProjectSelected:
				renderAll();

			case ProjectSettingsChanged, WorldSettingsChanged:
				renderAll();
				editor.camera.fit();

			case LevelRestoredFromHistory(l):
				invalidateLevel(l);

			case LevelSelected(l):
				invalidateLevel(l);
				updateLayout();

			case LevelResized(l):
				invalidateLevel(l);
				updateLayout();
				renderWorldBounds();

			case LevelSettingsChanged(l):
				invalidateLevel(l);
				renderWorldBounds();

			case LayerDefRemoved(uid):
				renderAll();

			case LayerDefSorted:
				renderAll();

			case LayerDefChanged, LayerDefConverted:
				renderAll();

			case TilesetDefPixelDataCacheRebuilt(td):
				renderAll();

			case LevelAdded(l):
				invalidateLevel(l);
				updateLayout();
				renderWorldBounds();
				// if( editor.worldMode )
				// 	camera.scrollToLevel(l);

			case LevelRemoved(l):
				removeLevel(l);
				updateLayout();
				renderWorldBounds();

			case LevelSorted:
				updateLayout();
				renderWorldBounds();

			case _:
		}
	}

	public inline function invalidateLevel(l:data.Level) {
		levelInvalidations.set(l.uid, true);
	}

	public function renderAll() {
		App.LOG.render("Reset world render");

		for(l in levels.keys())
			removeLevel(l);
		levels = new Map();
		levelsWrapper.removeChildren();

		for(l in editor.project.levels)
			invalidateLevel(l);

		renderBg();
		renderAxes();
		renderWorldBounds();
		updateLayout();
	}

	function renderBg() {
		worldBg.tex.resize( camera.iWidth, camera.iHeight );
		worldBg.col.tile = h2d.Tile.fromColor( C.interpolateInt(editor.project.bgColor, 0x8187bd, 0.85) );
		worldBg.col.scaleX = camera.width;
		worldBg.col.scaleY = camera.height;
	}

	function updateLabels() {
		for( l in editor.project.levels ) {
			if( !levels.exists(l.uid) )
				continue;

			var e = levels.get(l.uid);
			var scale = camera.pixelRatio>1 ? ( 1.5 * camera.pixelRatio ) : 1;
			e.label.setScale( scale / camera.adjustedZoom);
			e.label.x = Std.int( l.worldX + l.pxWid*0.5 - e.label.width*e.label.scaleX*0.5 );
			e.label.y = l.worldY + 8;
		}
	}

	function renderAxes() {
		axes.clear();
		axes.lineStyle(2*editor.camera.pixelRatio, 0x0, 0.15);

		// Horizontal
		axes.moveTo(0, root.y);
		axes.lineTo(camera.iWidth, root.y);

		// Vertical
		axes.moveTo(root.x, 0);
		axes.lineTo(root.x, camera.iHeight);
	}

	function renderWorldBounds() {
		var pad = editor.project.defaultGridSize*3;
		var b = editor.project.getWorldBounds();
		worldBounds.clear();
		worldBounds.beginFill(editor.project.bgColor, 0.8);
		worldBounds.drawRoundedRect(
			b.left-pad,
			b.top-pad,
			b.right-b.left+1+pad*2,
			b.bottom-b.top+1+pad*2,
			pad*0.5
		);
	}

	public function updateLayout() {
		var cur = editor.curLevel;

		// Axes visibility
		axes.visible = editor.worldMode && switch editor.project.worldLayout {
			case Free: true;
			case WorldGrid: true;
			case LinearHorizontal: false;
			case LinearVertical: false;
		};

		// Level layout
		for( l in editor.project.levels )
			if( levels.exists(l.uid) ) {
				var e = levels.get(l.uid);

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
					var dist = cur.getBoundsDist(l);
					e.bounds.alpha = 0.33;
					e.render.alpha = 0.33;
					e.render.visible = dist<=300;
				}

				// Position
				e.render.setPosition( l.worldX, l.worldY );
				e.bounds.setPosition( l.worldX, l.worldY );
				e.bg.setPosition( l.worldX, l.worldY );
			}

		updateLabels();
	}

	function removeLevel(?l:data.Level, ?uid:Int) {
		if( l==null && uid==null )
			throw "Need 1 parameter";

		if( l!=null )
			uid = l.uid;

		if( levels.exists(uid) ) {
			var lr = levels.get(uid);
			lr.render.remove();
			lr.bounds.remove();
			lr.bg.remove();
			lr.label.remove();
			levels.remove(uid);
		}
	}

	function renderLevel(l:data.Level) {
		if( l==null )
			throw "Unknown level";

		App.LOG.render("Rendered world level "+l);

		// Cleanup
		levelInvalidations.remove(l.uid);
		removeLevel(l);

		// Init
		var wl = {
			bg : new h2d.Bitmap(),
			render : new h2d.Object(),
			bounds : new h2d.Graphics(),
			label : new h2d.ScaleGrid(Assets.elements.getTile("fieldBg"), 2, 2),
		}
		var _depth = 0;
		levelsWrapper.add(wl.bg, _depth++);
		levelsWrapper.add(wl.render, _depth++);
		levelsWrapper.add(wl.bounds, _depth++);
		levelsWrapper.add(wl.label, _depth++);
		levels.set(l.uid, wl);

		// Bg
		wl.bg.tile = h2d.Tile.fromColor(l.getBgColor());
		wl.bg.scaleX = l.pxWid;
		wl.bg.scaleY = l.pxHei;

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
		var thick = 1*camera.pixelRatio;
		var c = l==editor.curLevel ? 0xffffff :  C.toWhite(l.getBgColor(),0.4);
		wl.bounds.beginFill(c);
		wl.bounds.drawRect(0, 0, l.pxWid, thick); // top

		wl.bounds.beginFill(c);
		wl.bounds.drawRect(0, l.pxHei-thick, l.pxWid, thick); // bottom

		wl.bounds.beginFill(c);
		wl.bounds.drawRect(0, 0, thick, l.pxHei); // left

		wl.bounds.beginFill(c);
		wl.bounds.drawRect(l.pxWid-thick, 0, thick, l.pxHei); // right

		// Identifier
		wl.label.color.setColor( C.addAlphaF(0x464e79) );
		wl.label.alpha = 0.8;

		var tf = new h2d.Text(Assets.fontPixel, wl.label);
		tf.text = l.identifier;
		tf.textColor = 0xffcc00;
		tf.x = 4;

		wl.label.width = tf.x*2 + tf.textWidth;
		wl.label.height = tf.textHeight;
	}


	override function postUpdate() {
		super.postUpdate();

		worldBg.wrapper.alpha += ( ( editor.worldMode ? 0.3 : 0 ) - worldBg.wrapper.alpha ) * 0.1;
		worldBg.wrapper.visible = worldBg.wrapper.alpha>=0.02;
		worldBounds.visible = editor.worldMode && editor.project.levels.length>1;

		// World levels invalidation (max one per frame)
		for( uid in levelInvalidations.keys() ) {
			renderLevel( editor.project.getLevel(uid) );
			updateLayout();
			break;
		}
	}

}
