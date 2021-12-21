package display;

typedef WorldLevelRender = {
	var bgWrapper: h2d.Object;
	var bounds: h2d.Graphics;
	var render: h2d.Object;
	var label: h2d.ScaleGrid;
}

class WorldRender extends dn.Process {
	public var editor(get,never) : Editor; inline function get_editor() return Editor.ME;
	public var camera(get,never) : display.Camera; inline function get_camera() return Editor.ME.camera;
	public var project(get,never) : data.Project; inline function get_project() return Editor.ME.project;
	public var settings(get,never) : Settings; inline function get_settings() return App.ME.settings;

	var worldBgColor(get,never) : UInt;
		inline function get_worldBgColor() return C.interpolateInt(project.bgColor, 0x8187bd, 0.85);

	var worldLineColor(get,never) : UInt;
		inline function get_worldLineColor() return C.toWhite(worldBgColor, 0.0);

	var levels : Map<Int,WorldLevelRender> = new Map();
	var worldBg : { wrapper:h2d.Object, col:h2d.Bitmap, tex:dn.heaps.TiledTexture };
	var worldBounds : h2d.Graphics;
	var title : h2d.Text;
	var axes : h2d.Graphics;
	var grids : h2d.Graphics;
	var currentHighlight : h2d.Graphics;
	public var levelsWrapper : h2d.Layers;
	var fieldsWrapper : h2d.Object;
	var fieldRenders : Map<Int, { customFields:h2d.Flow, identifier:h2d.Flow }> = new Map();

	var levelInvalidations : Map<Int,Bool> = new Map();
	var levelFieldsInvalidation : Map<Int,Bool> = new Map();


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
		worldBg.col.colorAdd = new h3d.Vector(0,0,0,0);
		worldBg.tex.alpha = 0.5;
		editor.root.add(worldBg.wrapper, Const.DP_BG);
		worldBg.wrapper.alpha = 0;

		worldBounds = new h2d.Graphics();
		// editor.root.add(worldBounds, Const.DP_BG);

		grids = new h2d.Graphics();
		editor.root.add(grids, Const.DP_BG);

		axes = new h2d.Graphics();
		editor.root.add(axes, Const.DP_BG);

		title = new h2d.Text(Assets.fontLight_title);
		title.text = "hello world";
		editor.root.add(title, Const.DP_TOP);

		currentHighlight = new h2d.Graphics();
		root.add(currentHighlight, Const.DP_TOP);

		levelsWrapper = new h2d.Layers();
		root.add(levelsWrapper, Const.DP_MAIN);

		fieldsWrapper = new h2d.Object();
		root.add(fieldsWrapper, Const.DP_TOP);
	}

	override function onDispose() {
		super.onDispose();
		worldBg.wrapper.remove();
		title.remove();
		axes.remove();
		grids.remove();
		currentHighlight.remove();
		editor.ge.removeListener(onGlobalEvent);
	}

	override function onResize() {
		super.onResize();
		updateTitle();
		renderAxes();
		renderGrids();
		renderBg();
		updateCurrentHighlight();
	}

	function onGlobalEvent(e:GlobalEvent) {
		switch e {
			case AppSettingsChanged:
				renderAll();

			case WorldMode(active):
				if( active )
					invalidateLevel(editor.curLevel);

				renderGrids();
				updateLayout();
				updateFieldsPos();
				updateCurrentHighlight();

			case ViewportChanged:
				root.setScale( camera.adjustedZoom );
				root.x = M.round( camera.width*0.5 - camera.worldX * camera.adjustedZoom );
				root.y = M.round( camera.height*0.5 - camera.worldY * camera.adjustedZoom );
				renderAxes();
				renderGrids();
				updateBgColor();
				updateLabels();
				updateTitle();
				updateFieldsPos();
				updateCurrentHighlight();

			case GridChanged(active):
				renderGrids();

			case WorldLevelMoved(l):
				updateLayout();
				updateLabels(true);
				updateCurrentHighlight();

			case ProjectSaved:
				invalidateAllLevelFields();
				updateLabels(true);

			case LevelJsonCacheInvalidated(l):
				updateLabels(true);

			case ProjectSelected:
				renderAll();

			case EnumDefChanged, EnumDefAdded, EnumDefRemoved, EnumDefValueRemoved:
				invalidateAllLevelFields();

			case EntityFieldInstanceChanged(ei,fi):

			case LevelFieldInstanceChanged(l,fi):
				invalidateLevelFields(l);

			case FieldDefRemoved(fd):
				invalidateAllLevelFields();

			case FieldDefChanged(fd):
				invalidateAllLevelFields();

			case FieldDefSorted:
				invalidateAllLevelFields();

			case ProjectSettingsChanged, WorldSettingsChanged:
				renderAll();
				editor.camera.fit();

			case LevelRestoredFromHistory(l):
				invalidateLevel(l);
				invalidateLevelFields(l);
				updateCurrentHighlight();

			case LevelSelected(l):
				invalidateLevel(l);
				invalidateLevelFields(l);
				updateLayout();

			case LevelResized(l):
				invalidateLevel(l);
				invalidateLevelFields(l);
				updateTitle();
				updateLayout();
				renderWorldBounds();
				updateCurrentHighlight();

			case LevelSettingsChanged(l):
				invalidateLevel(l);
				invalidateLevelFields(l);
				renderWorldBounds();
				updateTitle();
				updateCurrentHighlight();

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
				invalidateLevelFields(l);
				updateLayout();
				updateLabels(true);
				renderWorldBounds();

			case LevelRemoved(l):
				removeLevel(l.uid);
				removeLevelFields(l.uid);
				updateLayout();
				updateLabels(true);
				renderWorldBounds();

			case ShowDetailsChanged(active):
				fieldsWrapper.visible = active;
				if( active )
					invalidateAllLevelFields();
				else
					updateFieldsPos();
				updateTitle();
				updateLabels(active);
				renderAxes();
				for(l in project.levels)
					updateLevelBounds(l);

			case _:
		}
	}

	public inline function invalidateLevel(l:data.Level) {
		levelInvalidations.set(l.uid, true);
	}

	public inline function invalidateLevelFields(l:data.Level) {
		levelFieldsInvalidation.set(l.uid, true);
	}

	public inline function invalidateAllLevelFields() {
		for(l in project.levels)
			invalidateLevelFields(l);
	}

	public function renderAll() {
		App.LOG.render("Reset world render");

		for(uid in levels.keys()) {
			removeLevel(uid);
			removeLevelFields(uid);
		}
		levels = new Map();
		levelsWrapper.removeChildren();

		for(l in editor.project.levels) {
			invalidateLevelFields(l);
			invalidateLevel(l);
		}

		renderBg();
		renderAxes();
		renderGrids();
		renderWorldBounds();
		updateLayout();
	}


	function updateBgColor() {
		var r = -M.fclamp( 0.9 * 0.04/camera.adjustedZoom, 0, 1);
		worldBg.col.colorAdd.set(r,r,r,0);
	}

	function renderBg() {
		worldBg.tex.resize( camera.iWidth, camera.iHeight );
		worldBg.col.tile = h2d.Tile.fromColor(worldBgColor);
		worldBg.col.scaleX = camera.width;
		worldBg.col.scaleY = camera.height;
		updateBgColor();
	}

	function updateTitle() {
		title.visible = editor.worldMode && settings.v.showDetails;
		if( title.visible ) {
			var b = project.getWorldBounds();
			var w = b.right-b.left;
			var t = project.filePath.fileName;
			title.textColor = C.toWhite(project.bgColor, 0.3);
			title.text = t;
			title.setScale( camera.adjustedZoom * M.fmin(8, (w/title.textWidth) * 2) );
			title.x = Std.int( (b.left + b.right)*0.5*camera.adjustedZoom + root.x - title.textWidth*0.5*title.scaleX );
			title.y = Std.int( b.top*camera.adjustedZoom - 64 + root.y - title.textHeight*title.scaleY );
		}
	}

	function updateFieldsPos() {
		if( !settings.v.showDetails )
			return;

		var padding = Std.int( Rulers.PADDING*3 );
		for(f in fieldRenders.keyValueIterator()) {
			var l = project.getLevel(f.key);
			var fr = f.value;
			fr.customFields.visible = editor.worldMode || editor.curLevel==l;
			fr.identifier.visible = !editor.worldMode && camera.adjustedZoom>=getMinVisibilityZoom();
			if( editor.worldMode )
				fr.customFields.alpha = getAlphaFromZoom();

			if( !fr.customFields.visible )
				continue;

			// Custom fields
			if( editor.worldMode ) {
				switch project.worldLayout {
					case Free, GridVania:
						fr.customFields.x = Std.int( l.worldCenterX - fr.customFields.outerWidth*0.5*fr.customFields.scaleX );
						fr.customFields.y = Std.int( l.worldY + l.pxHei - fr.customFields.outerHeight*fr.customFields.scaleY );
						fr.customFields.setScale( M.fmin(1/camera.adjustedZoom, M.fmin( l.pxWid/fr.customFields.outerWidth, l.pxHei/fr.customFields.outerHeight) ) );

					case LinearHorizontal:
						fr.customFields.setScale( M.fmin(1/camera.adjustedZoom, l.pxWid/fr.customFields.outerWidth ) );
						fr.customFields.x = Std.int( l.worldCenterX - fr.customFields.outerWidth*0.5*fr.customFields.scaleX );
						fr.customFields.y = Std.int( l.worldY + l.pxHei + 32 );

					case LinearVertical:
						fr.customFields.setScale( M.fmin(1/camera.adjustedZoom, l.pxHei/fr.customFields.outerHeight ) );
						fr.customFields.x = Std.int( l.worldX + l.worldX+l.pxWid+32 );
						fr.customFields.y = Std.int( l.worldCenterY - fr.customFields.outerHeight*0.5*fr.customFields.scaleY );
				}
			}
			else {
				fr.customFields.setScale( M.fmin(1/camera.adjustedZoom, M.fmin( l.pxWid/fr.customFields.outerWidth, l.pxHei/fr.customFields.outerHeight) ) );
				fr.customFields.x = Std.int( l.worldCenterX - fr.customFields.outerWidth*0.5*fr.customFields.scaleX );
				fr.customFields.y = Std.int( l.worldY - padding - fr.customFields.outerHeight*fr.customFields.scaleY );
			}
		}
	}

	inline function getMinVisibilityZoom() {
		return camera.getMinZoom();
		// return switch project.worldLayout {
		// 	case Free, GridVania: 0.06;
		// 	case LinearVertical: 0.04;
		// 	case LinearHorizontal: 0.04;
		// }
	}

	inline function getAlphaFromZoom() {
		var minZoom = camera.getMinZoom();
		return M.fmin( (camera.adjustedZoom-minZoom)/minZoom, 1 );
	}

	function updateLabels(refreshTexts=false) {
		for( l in editor.project.levels ) {
			if( !levels.exists(l.uid) )
				continue;

			// Update text
			if( refreshTexts )
				updateLabelText(l);

			var e = levels.get(l.uid);

			// Visibility
			e.label.visible = camera.adjustedZoom>=getMinVisibilityZoom() && ( l!=editor.curLevel || editor.worldMode ) && settings.v.showDetails;
			if( !e.label.visible )
				continue;
			e.label.alpha = getAlphaFromZoom();

			// Scaling
			switch project.worldLayout {
				case Free, GridVania:
					e.label.setScale( M.fmin( l.pxWid / e.label.width, 1/camera.adjustedZoom ) );

				case LinearHorizontal, LinearVertical:
					e.label.setScale( 1/camera.adjustedZoom );
			}

			// Position
			switch project.worldLayout {
				case Free, GridVania:
					e.label.x = Std.int( l.worldX );
					e.label.y = Std.int( l.worldY );

				case LinearHorizontal:
					e.label.x = Std.int( l.worldX + l.pxWid*0.3 );
					e.label.y = Std.int( l.worldY - e.label.height*e.label.scaleY );
					e.label.smooth = true;
					e.label.rotation = -0.4;

				case LinearVertical:
					e.label.x = Std.int( l.worldX - e.label.width*e.label.scaleX - 30 );
					e.label.y = Std.int( l.worldY + l.pxHei*0.5 - e.label.height*e.label.scaleY*0.5 );
			}

			// Color
			e.label.color.setColor( C.addAlphaF( C.toBlack( l.getBgColor(), 0.8 ) ) );
		}

	}

	function renderGrids() {
		grids.clear();

		if( !editor.worldMode )
			return;

		// Base level grid
		if( project.worldLayout==Free && camera.adjustedZoom>=1.5 && settings.v.grid ) {
			grids.lineStyle(camera.pixelRatio, worldLineColor, 0.4 * M.fmin( (camera.adjustedZoom-1.5)/0.6, 1 ) );
			var g = project.getSmartLevelGridSize() * camera.adjustedZoom;
			var off = root.x % g;
			for(i in 0...M.ceil(camera.width/g)) {
				grids.moveTo(i*g+off, 0);
				grids.lineTo(i*g+off, camera.height);
			}
			var off = root.y % g;
			for(i in 0...M.ceil(camera.height/g)) {
				grids.moveTo(0, i*g+off);
				grids.lineTo(camera.width, i*g+off);
			}
		}

		// World grid
		if( project.worldLayout==GridVania && camera.adjustedZoom>=0.2 ) {
			grids.lineStyle(camera.pixelRatio, worldLineColor, 0.4 * M.fmin( (camera.adjustedZoom-0.2)/0.3, 1 ) );
			var g = project.worldGridWidth * camera.adjustedZoom;
			var off =  root.x % g;
			for( i in 0...M.ceil(camera.width/g)+1 ) {
				grids.moveTo(i*g+off, 0);
				grids.lineTo(i*g+off, camera.height);
			}
			var g = project.worldGridHeight * camera.adjustedZoom;
			var off =  root.y % g;
			for( i in 0...M.ceil(camera.height/g)+1 ) {
				grids.moveTo(0, i*g+off);
				grids.lineTo(camera.width, i*g+off);
			}
		}
	}


	function renderAxes() {
		axes.clear();
		if( !settings.v.showDetails )
			return;

		axes.lineStyle(3*camera.pixelRatio, worldLineColor, 1);

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

	function updateCurrentHighlight() {
		currentHighlight.visible = editor.worldMode;
		if( !currentHighlight.visible )
			return;

		currentHighlight.clear();
		currentHighlight.lineStyle(7/camera.adjustedZoom, 0xffcc00);
		var l = editor.curLevel;
		var p = 2 / camera.adjustedZoom;
		currentHighlight.drawRect(l.worldX-p, l.worldY-p, l.pxWid+p*2, l.pxHei+p*2);
	}

	public function updateLayout() {
		var cur = editor.curLevel;

		// Axes visibility
		axes.visible = editor.worldMode && switch editor.project.worldLayout {
			case Free: true;
			case GridVania: true;
			case LinearHorizontal: false;
			case LinearVertical: false;
		};

		// Level layout
		for( l in editor.project.levels )
			if( levels.exists(l.uid) ) {
				var e = levels.get(l.uid);

				e.bgWrapper.alpha = editor.worldMode ? 1 : 0.2;

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
					e.bounds.alpha = 0.3;
					e.render.alpha = 0.5;
					e.render.visible = dist<=300;
				}

				// Position
				e.render.setPosition( l.worldX, l.worldY );
				e.bounds.setPosition( l.worldX, l.worldY );
				e.bgWrapper.setPosition( l.worldX, l.worldY );
			}

		updateLabels();
	}

	function removeLevel(uid:Int) {
		if( levels.exists(uid) ) {
			var lr = levels.get(uid);
			lr.render.remove();
			lr.bounds.remove();
			lr.bgWrapper.remove();
			lr.label.remove();
			levels.remove(uid);
		}
	}

	function removeLevelFields(uid:Int) {
		if( fieldRenders.exists(uid) ) {
			fieldRenders.get(uid).customFields.remove();
			fieldRenders.remove(uid);
		}
	}

	function renderFields(l:data.Level) {
		levelFieldsInvalidation.remove(l.uid);

		// Init wrapper
		if( !fieldRenders.exists(l.uid) ) {
			fieldRenders.set(l.uid, {
				customFields: {
					var f = new h2d.Flow(fieldsWrapper);
					f.layout = Vertical;
					f;
				},
				identifier: null,
			});
		}
		var fWrapper = fieldRenders.get(l.uid);
		fWrapper.customFields.removeChildren();

		// Attach custom fields
		FieldInstanceRender.renderFields(
			project.defs.levelFields.map( fd->l.getFieldInstance(fd) ),
			l.getSmartColor(true),
			LevelCtx(l),
			fWrapper.customFields
		);

		// Level identifier
		var f = new h2d.Flow(fWrapper.customFields);
		f.minWidth = f.maxWidth = fWrapper.customFields.outerWidth;
		f.horizontalAlign = Middle;
		f.padding = 6;
		var tf = new h2d.Text(Assets.getLargeFont(), f);
		tf.smooth = true;
		tf.text = l.getDisplayIdentifier();
		tf.textColor = l.getSmartColor(true);
		FieldInstanceRender.addBg(f, l.getSmartColor(true), 0.85);
		if( fWrapper.identifier!=null )
			fWrapper.identifier.remove();
		fWrapper.identifier = f;

		updateFieldsPos();
	}

	function renderLevel(l:data.Level) {
		if( l==null )
			throw "Unknown level";

		App.LOG.render("Rendered world level "+l);

		// Cleanup
		levelInvalidations.remove(l.uid);
		removeLevel(l.uid);

		// Init
		var wl : WorldLevelRender = {
			bgWrapper: new h2d.Object(),
			render : new h2d.Object(),
			bounds : new h2d.Graphics(),
			label : new h2d.ScaleGrid(Assets.elements.getTile("fieldBgOutline"), 2, 2),
		}
		var _depth = 0;
		levelsWrapper.add(wl.bgWrapper, _depth++);
		levelsWrapper.add(wl.render, _depth++);
		levelsWrapper.add(wl.label, _depth++);
		levelsWrapper.add(wl.bounds, _depth++);
		levels.set(l.uid, wl);

		// Bg color
		var col = new h2d.Bitmap(h2d.Tile.fromColor(l.getBgColor()), wl.bgWrapper);
		col.scaleX = l.pxWid;
		col.scaleY = l.pxHei;

		// Bg image
		l.createBgBitmap(wl.bgWrapper);

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

		// Render layers
		for( li in l.layerInstances ) {
			if( li.def.type==Entities )
				continue;

			if( li.def.isAutoLayer() && li.autoTilesCache==null )
				App.LOG.error("missing autoTilesCache in "+li);

			if( li.def.isAutoLayer() && li.autoTilesCache!=null ) {
				// Auto layer
				var td = li.getTilesetDef();
				if( td!=null && td.isAtlasLoaded() ) {
					var pixelGrid = new dn.heaps.PixelGrid(li.def.gridSize, li.cWid, li.cHei, wl.render);
					pixelGrid.x = li.pxTotalOffsetX;
					pixelGrid.y = li.pxTotalOffsetY;
					var c = 0x0;
					var cx = 0;
					var cy = 0;
					li.def.iterateActiveRulesInDisplayOrder( li, (r)->{
						if( li.autoTilesCache.exists( r.uid ) ) {
							for( allTiles in li.autoTilesCache.get( r.uid ).keyValueIterator() )
							for( tileInfos in allTiles.value ) {
								cx = Std.int( tileInfos.x / li.def.gridSize );
								cy = Std.int( tileInfos.y / li.def.gridSize );
								if( !isCoordDone(li,cx,cy) ) {
									c = td.getAverageTileColor(tileInfos.tid);
									// if( C.getA(c)>=1 )
										markCoordAsDone(li,cx,cy);
									pixelGrid.setPixel24(cx,cy, c);
								}
							}
						}
					});
				}
			}
			else if( li.def.type==IntGrid ) {
				// Pure intGrid
				var pixelGrid = new dn.heaps.PixelGrid(li.def.gridSize, li.cWid, li.cHei, wl.render);
				pixelGrid.x = li.pxTotalOffsetX;
				pixelGrid.y = li.pxTotalOffsetY;
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
				var td = li.getTilesetDef();
				if( td!=null && td.isAtlasLoaded() ) {
					var pixelGrid = new dn.heaps.PixelGrid(li.def.gridSize, li.cWid, li.cHei, wl.render);
					pixelGrid.x = li.pxTotalOffsetX;
					pixelGrid.y = li.pxTotalOffsetY;
					var c = 0x0;
					for(cy in 0...li.cHei)
					for(cx in 0...li.cWid)
						if( !isCoordDone(li,cx,cy) && li.hasAnyGridTile(cx,cy) ) {
							c = td.getAverageTileColor( li.getTopMostGridTile(cx,cy).tileId );
							if( C.getA(c)>=1 )
								markCoordAsDone(li, cx,cy);
							pixelGrid.setPixel24(cx,cy, c);
						}
				}
			}
		}

		updateLevelBounds(l);

		// Identifier
		wl.label.color.setColor( C.addAlphaF(0x464e79) );
		wl.label.alpha = 0.8;
		updateLabelText(l);
	}


	function updateLevelBounds(l:data.Level) {
		var wl = levels.get(l.uid);
		if( wl!=null ) {
			wl.bounds.clear();
			if( !settings.v.showDetails )
				return;

			var error = l.getFirstError();

			var thick = 2*camera.pixelRatio;
			var c = l==editor.curLevel ? 0xffffff :  C.toWhite(l.getBgColor(),0.4);
			if( error!=null ) {
				thick*=8;
				c = 0xff0000;
			}
			wl.bounds.beginFill(c);
			wl.bounds.drawRect(0, 0, l.pxWid, thick); // top

			wl.bounds.beginFill(c);
			wl.bounds.drawRect(0, l.pxHei-thick, l.pxWid, thick); // bottom

			wl.bounds.beginFill(c);
			wl.bounds.drawRect(0, 0, thick, l.pxHei); // left

			wl.bounds.beginFill(c);
			wl.bounds.drawRect(l.pxWid-thick, 0, thick, l.pxHei); // right
		}
	}


	function updateLabelText(l:data.Level) {
		var wl = levels.get(l.uid);
		if( wl==null )
			return;

		wl.label.removeChildren();
		var error = l.getFirstError();
		var tf = new h2d.Text(Assets.getRegularFont(), wl.label);
		tf.smooth = true;
		tf.text = l.getDisplayIdentifier();
		tf.textColor = C.toWhite( l.getSmartColor(false), 0.65 );
		tf.x = 8;
		tf.smooth = true;

		if( error!=null ) {
			tf.textColor = 0xff0000;
			tf.text +=
				" <ERR: " + ( switch error {
					case null: '???';
					case InvalidEntityField(ei): '${ei.def.identifier}';
					case InvalidBgImage: 'bg image';
				}) + ">";
		}

		wl.label.width = tf.x*2 + tf.textWidth;
		wl.label.height = tf.textHeight;
	}


	override function postUpdate() {
		super.postUpdate();

		worldBg.wrapper.alpha += ( ( editor.worldMode ? 0.3 : 0 ) - worldBg.wrapper.alpha ) * 0.1;
		worldBg.wrapper.visible = worldBg.wrapper.alpha>=0.02;
		worldBounds.visible = editor.worldMode && editor.project.levels.length>1;

		var waitTileset = false;
		for(td in project.defs.tilesets)
			if( td.hasAtlasPath() && !td.hasValidPixelData() && NT.fileExists(project.makeAbsoluteFilePath(td.relPath)) ) {
				waitTileset = true;
				break;
			}

		// World levels rendering (max one per frame)
		if( !waitTileset )
			for( uid in levelInvalidations.keys() ) {
				if( editor.project.getLevel(uid)==null ) {
					levelInvalidations.remove(uid);
					continue;
				}
				renderLevel( editor.project.getLevel(uid) );
				updateLayout();
				break;
			}

		// Fields
		var limit = 15;
		for( uid in levelFieldsInvalidation.keys() ) {
			var l = editor.project.getLevel(uid);
			renderFields(l);
			updateLabelText(l);
			if( limit--<=0 )
				break;
		}
	}

}
