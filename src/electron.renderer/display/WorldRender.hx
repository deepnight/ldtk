package display;

typedef WorldLevelRender = {
	var bgWrapper: h2d.Object;
	var bounds: h2d.Graphics;
	var render: h2d.Object;
	var identifier: h2d.ScaleGrid;
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

	var worldLevels : Map<Int,WorldLevelRender> = new Map();
	var worldBg : { wrapper:h2d.Object, col:h2d.Bitmap, tex:dn.heaps.TiledTexture };
	var worldBounds : h2d.Graphics;
	var title : h2d.Text;
	var axes : h2d.Graphics;
	var grids : h2d.Graphics;
	var currentHighlight : h2d.Graphics;
	public var worldLevelsWrapper : h2d.Layers;
	var fieldsWrapper : h2d.Object;
	var fieldRenders : Map<Int, { customFields:h2d.Flow, identifier:h2d.Flow }> = new Map();

	var levelRenderInvalidations : Map<Int,Bool> = new Map();
	var levelFieldsInvalidation : Map<Int,Bool> = new Map();
	var levelIdentifiersInvalidation : Map<Int,Bool> = new Map();


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

		worldLevelsWrapper = new h2d.Layers();
		root.add(worldLevelsWrapper, Const.DP_MAIN);

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
		updateWorldTitle();
		renderAxes();
		renderGrids();
		renderWorldBg();
		updateCurrentHighlight();
	}

	function onGlobalEvent(e:GlobalEvent) {
		switch e {
			case AppSettingsChanged:
				renderAll();

			case WorldMode(active):
				if( active )
					invalidateLevelRender(editor.curLevel);

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
				updateAllLevelIdentifiers(false);
				updateWorldTitle();
				updateFieldsPos();
				updateCurrentHighlight();
				for(l in project.levels)
					updateLevelVisibility(l);

			case GridChanged(active):
				renderGrids();

			case WorldLevelMoved(l):
				updateLayout();
				updateCurrentHighlight();

			case ProjectSaved:
				invalidateAllLevelFields();
				invalidateAllLevelIdentifiers();

			case LevelJsonCacheInvalidated(l):
				invalidateAllLevelIdentifiers();

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

			case ProjectSettingsChanged:
				renderWorldBg();
				editor.camera.fit();

			case WorldSettingsChanged:
				renderGrids();
				invalidateAll();
				editor.camera.fit();

			case LevelRestoredFromHistory(l):
				invalidateLevelRender(l);
				invalidateLevelFields(l);
				updateCurrentHighlight();

			case LevelSelected(l):
				invalidateLevelRender(l);
				invalidateLevelFields(l);
				updateLayout();

			case LevelResized(l):
				invalidateLevelRender(l);
				invalidateLevelFields(l);
				updateWorldTitle();
				updateLayout();
				renderWorldBounds();
				updateCurrentHighlight();

			case LevelSettingsChanged(l):
				invalidateLevelRender(l);
				invalidateLevelFields(l);
				renderWorldBounds();
				updateWorldTitle();
				updateCurrentHighlight();

			case LayerDefRemoved(uid):
				invalidateAllLevelRenders();

			case LayerDefSorted:
				invalidateAllLevelRenders();

			case LayerDefChanged(_), LayerDefConverted:
				invalidateAllLevelRenders();

			case TilesetDefPixelDataCacheRebuilt(td):
				invalidateAllLevelRenders();

			case LevelAdded(l):
				invalidateLevelRender(l);
				invalidateLevelFields(l);
				updateLayout();
				renderWorldBounds();

			case LevelRemoved(l):
				removeLevel(l.uid);
				removeLevelFields(l.uid);
				updateLayout();
				invalidateAllLevelIdentifiers();
				renderWorldBounds();

			case ShowDetailsChanged(active):
				fieldsWrapper.visible = active;
				if( active )
					invalidateAllLevelFields();
				else
					updateFieldsPos();
				updateWorldTitle();
				updateAllLevelIdentifiers(active);
				renderAxes();
				for(l in project.levels)
					updateLevelBounds(l);

			case _:
		}
	}


	public inline function invalidateAll() {
		for(l in editor.project.levels) {
			invalidateLevelFields(l);
			invalidateLevelIdentifier(l);
			invalidateLevelRender(l);
		}
	}

	public inline function invalidateLevelRender(l:data.Level) {
		levelRenderInvalidations.set(l.uid, true);
	}
	public inline function invalidateAllLevelRenders() {
		for(l in project.levels)
			invalidateLevelRender(l);
	}


	public inline function invalidateLevelFields(l:data.Level) {
		levelFieldsInvalidation.set(l.uid, true);
	}
	public inline function invalidateAllLevelFields() {
		for(l in project.levels)
			invalidateLevelFields(l);
	}

	public inline function invalidateLevelIdentifier(l:data.Level) {
		levelIdentifiersInvalidation.set(l.uid, true);
	}
	public inline function invalidateAllLevelIdentifiers() {
		for(l in project.levels)
			invalidateLevelIdentifier(l);
	}



	/** Return world level if it exists, or create it otherwise **/
	function getWorldLevel(uid:Int) : WorldLevelRender {
		if( !worldLevels.exists(uid) ) {
			var wl : WorldLevelRender = {
				bgWrapper: new h2d.Object(),
				render : new h2d.Object(),
				bounds : new h2d.Graphics(),
				identifier : new h2d.ScaleGrid(Assets.elements.getTile("fieldBgOutline"), 2, 2),
			}

			var _depth = 0;
			worldLevelsWrapper.add(wl.bgWrapper, _depth++);
			worldLevelsWrapper.add(wl.render, _depth++);
			worldLevelsWrapper.add(wl.identifier, _depth++);
			worldLevelsWrapper.add(wl.bounds, _depth++);
			worldLevels.set(uid, wl);
		}
		return worldLevels.get(uid);
	}

	function renderAll() {
		App.LOG.render("Rendering all world...");

		for(uid in worldLevels.keys()) {
			removeLevel(uid);
			removeLevelFields(uid);
		}

		// Init world levels
		worldLevels = new Map();
		worldLevelsWrapper.removeChildren();
		for(l in project.levels)
			getWorldLevel(l.uid);

		for(l in editor.project.levels) {
			invalidateLevelFields(l);
			invalidateLevelIdentifier(l);
			invalidateLevelRender(l);
		}

		renderWorldBg();
		renderAxes();
		renderGrids();
		renderWorldBounds();
		updateLayout();
	}


	function updateBgColor() {
		var r = -M.fclamp( 0.9 * 0.04/camera.adjustedZoom, 0, 1);
		worldBg.col.colorAdd.set(r,r,r,0);
	}

	function renderWorldBg() {
		App.LOG.render('Rendering world bg...');
		worldBg.tex.resize( camera.iWidth, camera.iHeight );
		worldBg.col.tile = h2d.Tile.fromColor(worldBgColor);
		worldBg.col.scaleX = camera.width;
		worldBg.col.scaleY = camera.height;
		updateBgColor();
	}

	function updateWorldTitle() {
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

		var minZoom = 0.1;
		var padding = Std.int( Rulers.PADDING*3 );
		for(f in fieldRenders.keyValueIterator()) {
			var l = project.getLevel(f.key);
			var fr = f.value;
			if( !camera.isOnScreenLevel(l, 256) ) {
				fr.customFields.visible = false;
				continue;
			}
			fr.customFields.visible = editor.worldMode || editor.curLevel==l;
			fr.identifier.visible = !editor.worldMode && camera.adjustedZoom>=minZoom;
			if( editor.worldMode )
				fr.customFields.alpha = getAlphaFromZoom(minZoom);

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

	inline function getAlphaFromZoom(minZoom:Float) {
		return M.fmin( (camera.adjustedZoom-minZoom)/minZoom, 1 );
	}

	inline function updateAllLevelIdentifiers(refreshTexts:Bool) {
		for( l in editor.project.levels )
			if( worldLevels.exists(l.uid) )
				updateLevelIdentifier(l, refreshTexts);
	}

	function renderGrids() {
		if( !editor.worldMode ) {
			grids.visible = false;
			return;
		}

		// App.LOG.render("Rendering world grids...");
		grids.clear();
		grids.visible = true;

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
		if( !settings.v.showDetails ) {
			axes.visible = false;
			return;
		}

		axes.clear();
		axes.visible = true;
		axes.lineStyle(3*camera.pixelRatio, worldLineColor, 1);

		// Horizontal
		axes.moveTo(0, root.y);
		axes.lineTo(camera.iWidth, root.y);

		// Vertical
		axes.moveTo(root.x, 0);
		axes.lineTo(root.x, camera.iHeight);
	}

	function renderWorldBounds() {
		App.LOG.render("Rendering world bounds...");
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


	function updateLevelVisibility(l:data.Level) {
		var wl = getWorldLevel(l.uid);
		if( l.uid==editor.curLevelId && !editor.worldMode ) {
			// Hide current level in editor mode
			wl.bounds.visible = false;
			wl.render.visible = false;
		}
		else if( editor.worldMode ) {
			// Show everything in world mode
			wl.render.visible = wl.bounds.visible = camera.isOnScreenLevel(l);
			wl.bounds.alpha = 1;
			wl.render.alpha = 1;
		}
		else {
			// Fade other levels in editor mode
			var dist = editor.curLevel.getBoundsDist(l);
			wl.bounds.alpha = 0.3;
			wl.bounds.visible = camera.isOnScreenLevel(l);
			wl.render.alpha = 0.5;
			wl.render.visible = wl.bounds.visible && dist<=300;
		}
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
		for( l in editor.project.levels ) {
			if( !worldLevels.exists(l.uid) )
				continue;

			var wl = getWorldLevel(l.uid);
			wl.bgWrapper.alpha = editor.worldMode ? 1 : 0.2;

			updateLevelVisibility(l);

			// Position
			wl.render.setPosition( l.worldX, l.worldY );
			wl.bounds.setPosition( l.worldX, l.worldY );
			wl.bgWrapper.setPosition( l.worldX, l.worldY );
		}

		updateAllLevelIdentifiers(false);
	}

	function removeLevel(uid:Int) {
		if( worldLevels.exists(uid) ) {
			var wl = worldLevels.get(uid);
			wl.render.remove();
			wl.bounds.remove();
			wl.bgWrapper.remove();
			wl.identifier.remove();
			worldLevels.remove(uid);
		}
	}

	function clearLevelRender(uid:Int) {
		var wl = getWorldLevel(uid);
		wl.bgWrapper.removeChildren();
		wl.bounds.clear();
		wl.render.removeChildren();
	}

	function removeLevelFields(uid:Int) {
		if( fieldRenders.exists(uid) ) {
			fieldRenders.get(uid).customFields.remove();
			fieldRenders.remove(uid);
		}
	}

	function renderFields(l:data.Level) {
		App.LOG.render('Rendering world level fields $l...');

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
		FieldInstanceRender.addBg(f, l.getSmartColor(false), 0.6);
		if( fWrapper.identifier!=null )
			fWrapper.identifier.remove();
		fWrapper.identifier = f;

		updateFieldsPos();
	}

	function renderLevel(l:data.Level) {
		if( l==null )
			throw "Unknown level";

		App.LOG.render('Rendering world level $l...');

		// Cleanup
		clearLevelRender(l.uid);

		var wl = getWorldLevel(l.uid);

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
		wl.identifier.color.setColor( C.addAlphaF(0x464e79) );
		wl.identifier.alpha = 0.8;
		invalidateLevelIdentifier(l);
	}


	function updateLevelBounds(l:data.Level) {
		var wl = getWorldLevel(l.uid);
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


	function updateLevelIdentifier(l:data.Level, refreshTexts:Bool) {
		var wl = getWorldLevel(l.uid);

		// Refresh text
		if( refreshTexts ) {
			wl.identifier.removeChildren();
			var error = l.getFirstError();
			var tf = new h2d.Text(Assets.getRegularFont(), wl.identifier);
			tf.smooth = true;
			tf.text = l.getDisplayIdentifier();
			tf.textColor = l.getSmartColor(true);
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

			wl.identifier.width = tf.x*2 + tf.textWidth;
			wl.identifier.height = tf.textHeight;
		}

		// Visibility
		wl.identifier.visible = camera.adjustedZoom>=camera.getMinZoom() && ( l!=editor.curLevel || editor.worldMode ) && settings.v.showDetails;
		if( !wl.identifier.visible )
			return;

		wl.identifier.alpha = getAlphaFromZoom( camera.getMinZoom()*0.8 );

		// Scaling
		switch project.worldLayout {
			case Free, GridVania:
				wl.identifier.setScale( M.fmin( l.pxWid / wl.identifier.width, 1/camera.adjustedZoom ) );

			case LinearHorizontal, LinearVertical:
				wl.identifier.setScale( 1/camera.adjustedZoom );
		}

		// Position
		switch project.worldLayout {
			case Free, GridVania:
				wl.identifier.x = Std.int( l.worldX );
				wl.identifier.y = Std.int( l.worldY );

			case LinearHorizontal:
				wl.identifier.x = Std.int( l.worldX + l.pxWid*0.3 );
				wl.identifier.y = Std.int( l.worldY - wl.identifier.height*wl.identifier.scaleY );
				wl.identifier.smooth = true;
				wl.identifier.rotation = -0.4;

			case LinearVertical:
				wl.identifier.x = Std.int( l.worldX - wl.identifier.width*wl.identifier.scaleX - 30 );
				wl.identifier.y = Std.int( l.worldY + l.pxHei*0.5 - wl.identifier.height*wl.identifier.scaleY*0.5 );
		}

		// Color
		wl.identifier.color.setColor( C.addAlphaF( C.toBlack( l.getBgColor(), 0.8 ) ) );
	}


	override function postUpdate() {
		super.postUpdate();

		// Fade bg
		var ta = ( editor.worldMode ? 0.3 : 0 );
		if( worldBg.wrapper.alpha!=ta ) {
			worldBg.wrapper.alpha += ( ta - worldBg.wrapper.alpha ) * 0.1;
			if( M.fabs(worldBg.wrapper.alpha-ta) <= 0.03 )
				worldBg.wrapper.alpha = ta;
		}

		worldBg.wrapper.visible = worldBg.wrapper.alpha>=0.02;
		worldBounds.visible = editor.worldMode && editor.project.levels.length>1;

		// Check if a tileset is being loaded
		var waitTileset = false;
		for(td in project.defs.tilesets)
			if( td.hasAtlasPath() && !td.hasValidPixelData() && NT.fileExists(project.makeAbsoluteFilePath(td.relPath)) ) {
				waitTileset = true;
				break;
			}

		// World levels rendering (max one per frame)
		var limit = 1;
		if( !waitTileset )
			for( uid in levelRenderInvalidations.keys() ) {
				if( editor.project.getLevel(uid)==null ) {
					// Drop lost levels
					removeLevel(uid);
					levelRenderInvalidations.remove(uid);
					continue;
				}
				var l = editor.project.getLevel(uid);
				if( !camera.isOnScreenLevel(l) )
					continue;
				levelRenderInvalidations.remove(uid);
				renderLevel(l);
				updateLayout();
				if( --limit<=0 )
					break;
			}

		// Fields
		limit = 5;
		for( uid in levelFieldsInvalidation.keys() ) {
			if( !editor.worldMode && editor.curLevel.uid!=uid )
				continue;
			levelFieldsInvalidation.remove(uid);
			var l = editor.project.getLevel(uid);
			renderFields(l);
			if( --limit<=0 )
				break;
		}

		// Identifiers
		if( editor.worldMode ) {
			limit = 10;
			for( uid in levelIdentifiersInvalidation.keys() ) {
				levelIdentifiersInvalidation.remove(uid);
				updateLevelIdentifier( editor.project.getLevel(uid), true );
				if( --limit<=0 )
					break;
			}
		}
	}

}
