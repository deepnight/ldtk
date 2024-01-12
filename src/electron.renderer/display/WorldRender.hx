package display;

typedef WorldLevelRender = {
	var worldIid : String;
	var uid : Int;
	var rect : misc.WorldRect;

	var bgWrapper: h2d.Object;
	var outline: h2d.Graphics;
	var render: h2d.Object;
	var edgeLayers : Null< Map<Int, h2d.TileGroup> >;
	var fadeMask : h2d.Bitmap;
	var identifier: h2d.ScaleGrid;

	var renderInvalidated: Bool;
	var fieldsInvalidated: Bool;
	var identifierInvalidated: Bool;
	var boundsInvalidated: Bool;

	var fieldsRender: h2d.Flow;
}

class WorldRender extends dn.Process {
	public var editor(get,never) : Editor; inline function get_editor() return Editor.ME;
	public var camera(get,never) : display.Camera; inline function get_camera() return Editor.ME.camera;
	public var project(get,never) : data.Project; inline function get_project() return Editor.ME.project;
	var curWorld(get,never) : data.World; inline function get_curWorld() return Editor.ME.curWorld;
	public var settings(get,never) : Settings; inline function get_settings() return App.ME.settings;

	var fieldsPadding(get,never) : Int;
		inline function get_fieldsPadding() return Std.int( Rulers.PADDING*3 );

	var worldBgColor(get,never) : UInt;
		inline function get_worldBgColor() return C.interpolateInt(project.bgColor, 0x8187bd, 0.85);

	var worldLineColor(get,never) : UInt;
		inline function get_worldLineColor() return C.toWhite(worldBgColor, 0.0);

	var worldLevels : Map<Int,WorldLevelRender> = new Map();
	var worldBg : { wrapper:h2d.Object, col:h2d.Bitmap, tex:dn.heaps.TiledTexture };
	var worldBounds : h2d.Graphics;
	var title : h2d.Text;
	var axeH : h2d.Bitmap;
	var axeV : h2d.Bitmap;
	var largeGrid : h2d.Graphics;
	var smallGrid : h2d.Graphics;
	var currentHighlight : h2d.Graphics;
	public var worldLayers : Map<Int,h2d.Layers>;
	var fieldsWrapper : h2d.Object;

	var invalidatedCameraBasedRenders = true;



	public function new() {
		super(editor);

		editor.ge.addGlobalListener(onGlobalEvent);
		createRootInLayers(editor.root, Const.DP_MAIN);

		var w = new h2d.Object();
		worldBg = {
			wrapper : w,
			col: new h2d.Bitmap(w),
			tex: new dn.heaps.TiledTexture(1, 1, Assets.elements.getTile("largeStripes"), w),
		}
		worldBg.col.colorAdd = new h3d.Vector(0,0,0);
		worldBg.tex.alpha = 0.5;
		editor.root.add(worldBg.wrapper, Const.DP_BG);
		worldBg.wrapper.alpha = 0;

		worldBounds = new h2d.Graphics();

		largeGrid = new h2d.Graphics();
		editor.root.add(largeGrid, Const.DP_BG);

		smallGrid = new h2d.Graphics();
		editor.root.add(smallGrid, Const.DP_BG);

		axeH = new h2d.Bitmap( h2d.Tile.fromColor(0xffffff, 1, 1, 0.15) );
		editor.root.add(axeH, Const.DP_BG);

		axeV = new h2d.Bitmap( h2d.Tile.fromColor(0xffffff, 1, 1, 0.15) );
		editor.root.add(axeV, Const.DP_BG);

		title = new h2d.Text(Assets.fontLight_title);
		title.text = "hello world";
		editor.root.add(title, Const.DP_TOP);

		worldLayers = new Map();

		fieldsWrapper = new h2d.Object();
		root.add(fieldsWrapper, Const.DP_TOP);

		currentHighlight = new h2d.Graphics();
		root.add(currentHighlight, Const.DP_TOP);
	}

	override function onDispose() {
		super.onDispose();

		worldBg.wrapper.remove();
		title.remove();
		axeH.remove();
		axeV.remove();
		smallGrid.remove();
		largeGrid.remove();
		currentHighlight.remove();
		editor.ge.removeListener(onGlobalEvent);
	}

	override function onResize() {
		super.onResize();
		updateWorldTitle();
		updateAxesPos();
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
				updateCurrentHighlight();
				updateAxesPos();
				invalidateCameraBasedRenders();
				invalidateLevelFields(editor.curLevel);

				if( settings.v.nearbyTilesRenderingDist>0 )
					invalidateNearbyLevels(editor.curLevel);

			case WorldSelected(w):
				for(wl in worldLevels)
					removeWorldLevel(wl.uid);
				invalidateAll();

			case ViewportChanged(zoomChanged):
				root.setScale( camera.adjustedZoom );
				root.x = M.round( camera.width*0.5 - camera.worldX * camera.adjustedZoom );
				root.y = M.round( camera.height*0.5 - camera.worldY * camera.adjustedZoom );
				if( zoomChanged )
					renderGrids();
				updateBgColor();
				updateAxesPos();
				updateAllLevelIdentifiers(false);
				updateWorldTitle();
				updateFieldsPos();
				invalidateCameraBasedRenders();
				for(l in curWorld.levels) {
					if( zoomChanged )
						getWorldLevel(l).boundsInvalidated = true;
					updateLevelVisibility(l);
				}

			case WorldDepthSelected(worldDepth):
				for(l in curWorld.levels)
					updateLevelVisibility(l);
				updateCurrentHighlight();
				updateAllLevelIdentifiers(false);
				updateFieldsPos();

			case GridChanged(active):
				renderGrids();

			case WorldLevelMoved(l,isFinal, prevNeig):
				updateLayout();
				updateCurrentHighlight();
				invalidateAllLevelIdentifiers();
				refreshWorldLevelRect(l);
				if( isFinal ) {
					switch curWorld.worldLayout {
						case Free, GridVania:
						case LinearHorizontal, LinearVertical:
							for(l in curWorld.levels)
								refreshWorldLevelRect(l);
					}
				}

			case ProjectSaved:
				invalidateAllLevelFields();
				invalidateAllLevelIdentifiers();

			case LevelJsonCacheInvalidated(l):
				invalidateLevelFields(l);
				invalidateLevelIdentifier(l);

			case ProjectSelected:
				renderAll();

			case EnumDefChanged, EnumDefAdded, EnumDefRemoved, EnumDefValueRemoved:
				invalidateAllLevelFields();

			case EntityFieldInstanceChanged(ei,fi):

			case LevelFieldInstanceChanged(l,fi):
				if( fi.def.type==F_Tile )
					invalidateLevelRender(l);
				invalidateLevelFields(l);

			case FieldDefRemoved(fd):
				invalidateAllLevelFields();

			case FieldDefChanged(fd):
				invalidateAllLevelFields();
				if( fd.type==F_Tile && project.defs.isLevelField(fd) )
					invalidateAllLevelRenders();

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

				if( settings.v.nearbyTilesRenderingDist>0 )
					invalidateNearbyLevels(l);

			case LevelResized(l):
				invalidateLevelRender(l);
				invalidateLevelFields(l);
				updateWorldTitle();
				updateLayout();
				renderWorldBounds();
				updateCurrentHighlight();
				refreshWorldLevelRect(l);

			case LevelSettingsChanged(l):
				invalidateLevelRender(l);
				invalidateLevelFields(l);
				renderWorldBounds();
				updateWorldTitle();
				updateCurrentHighlight();
				applyWorldDepth(l);
				sortWorldDepths();
				refreshWorldLevelRect(l);

			case LayerRuleGroupAdded(rg):
				if( rg.rules.length>0 )
					invalidateAllLevelRenders();

			case LayerRuleGroupRemoved(rg):
				invalidateAllLevelRenders();

			case LayerDefAdded:
				invalidateAllLevelRenders();

			case LayerDefRemoved(uid):
				invalidateAllLevelRenders();

			case LayerDefSorted:
				invalidateAllLevelRenders();

			case LayerDefChanged(_), LayerDefConverted:
				invalidateAllLevelRenders();

			case LayerDefIntGridValueRemoved(defUid,value,used):

			case LayerInstanceSelected(curLi):
				updateEdgeLayersOpacity();

			case TilesetDefPixelDataCacheRebuilt(td):
				invalidateAllLevelRenders();

			case LevelAdded(l):
				invalidateLevelRender(l);
				invalidateLevelFields(l);
				invalidateAllLevelIdentifiers();
				updateLayout();
				renderWorldBounds();

			case LevelRemoved(l):
				removeWorldLevel(l.uid);
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
				updateAxesPos();
				renderGrids();
				updateCurrentHighlight();
				for(l in curWorld.levels)
					if( active )
						getWorldLevel(l).boundsInvalidated = true;
					else
						updateLevelBounds(l);

			case _:
		}
	}


	public inline function invalidateAll() {
		for(l in editor.curWorld.levels) {
			invalidateLevelFields(l);
			invalidateLevelIdentifier(l);
			invalidateLevelRender(l);
		}
	}

	inline function invalidateCameraBasedRenders() {
		invalidatedCameraBasedRenders = true;
	}

	public function invalidateNearbyLevels(near:data.Level) {
		if( near!=null )
			for(other in curWorld.levels) {
				if( other==near )
					continue;
				if( other.touches(near) )
					invalidateLevelRender(other);
				else if( getWorldLevel(other).edgeLayers!=null )
					invalidateLevelRender(other);
			}
	}

	public inline function invalidateLevelRender(l:data.Level) {
		var wl = getWorldLevel(l);
		if( wl!=null )
			wl.renderInvalidated = true;
	}
	public inline function invalidateAllLevelRenders() {
		for(l in curWorld.levels)
			invalidateLevelRender(l);
	}


	public inline function invalidateLevelFields(l:data.Level) {
		var wl = getWorldLevel(l);
		if( wl!=null )
			wl.fieldsInvalidated = true;
	}
	public inline function invalidateAllLevelFields() {
		for(l in curWorld.levels)
			invalidateLevelFields(l);
	}

	public inline function invalidateLevelIdentifier(l:data.Level) {
		var wl = getWorldLevel(l);
		if( wl!=null )
			wl.identifierInvalidated = true;
	}
	public inline function invalidateAllLevelIdentifiers() {
		for(l in curWorld.levels)
			invalidateLevelIdentifier(l);
	}



	/** Z-sort depths wrappers**/
	function sortWorldDepths() {
		for(d in curWorld.getLowestLevelDepth()...curWorld.getHighestLevelDepth()+1)
			if( worldLayers.exists(d) )
				root.under( worldLayers.get(d) );
	}

	/** Insert world level to its depth wrapper **/
	function applyWorldDepth(l:data.Level) {
		var wl = getWorldLevel(l);

		var worldLayer = getWorldDepthWrapper(l.worldDepth);
		var _inc = 0;
		worldLayer.add(wl.bgWrapper, _inc++);
		worldLayer.add(wl.render, _inc++);
		worldLayer.add(wl.fadeMask, _inc++);
		worldLayer.add(wl.identifier, _inc++);
		worldLayer.add(wl.outline, _inc++);
	}

	inline function getWorldDepthWrapper(depth:Int) : h2d.Layers {
		if( !worldLayers.exists(depth) ) {
			var l = new h2d.Layers();
			root.add(l, Const.DP_MAIN);
			worldLayers.set(depth,l);
			sortWorldDepths();
		}
		return worldLayers.get(depth);
	}

	/**
		Return world level if it exists, or create it otherwise.
	**/
	inline function getWorldLevel(l:data.Level) : WorldLevelRender {
		if( !worldLevels.exists(l.uid) ) {
			var wl : WorldLevelRender = {
				worldIid : l._world.iid,
				uid: l.uid,

				rect: WorldRect.fromLevel(l),
				bgWrapper: new h2d.Object(),
				render : new h2d.Object(),
				edgeLayers: null,
				outline : new h2d.Graphics(),
				fadeMask: new h2d.Bitmap( h2d.Tile.fromColor(l.getBgColor(),1,1, 0.3) ),
				identifier : new h2d.ScaleGrid(Assets.elements.getTile(D.elements.fieldBg), 2, 2),

				boundsInvalidated: true,
				renderInvalidated: true,
				fieldsInvalidated: true,
				identifierInvalidated: true,

				fieldsRender: null,
			}
			worldLevels.set(l.uid, wl);
			applyWorldDepth(l);
		}
		return worldLevels.get(l.uid);
	}



	function renderAll() {
		App.LOG.render("Rendering all world...");

		for(uid in worldLevels.keys())
			removeWorldLevel(uid);

		// Init world levels
		worldLevels = new Map();
		for(l in worldLayers)
			l.removeChildren();
		for(l in curWorld.levels)
			getWorldLevel(l);

		for(l in editor.curWorld.levels) {
			invalidateLevelFields(l);
			invalidateLevelIdentifier(l);
			invalidateLevelRender(l);
		}

		renderWorldBg();
		updateAxesPos();
		renderGrids();
		renderWorldBounds();
		updateLayout();
		sortWorldDepths();
	}

	function updateBgColor() {
		var r = -M.fclamp( 0.9 * 0.04/camera.adjustedZoom, 0, 1);
		worldBg.col.colorAdd.set(r,r,r);
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
		title.visible = editor.worldMode && settings.v.showDetails && !editor.gifMode;
		if( title.visible ) {
			var b = curWorld.getWorldBounds();
			var w = b.right-b.left;
			var t = project.hasFlag(MultiWorlds) ? curWorld.identifier : project.filePath.fileName;
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

		var minZoom = 0.2;

		for(wl in worldLevels) {
			if( wl.fieldsRender==null )
				continue;

			var l = project.getLevelAnywhere(wl.uid);
			if( !camera.isOnScreenLevel(l, 256) || l.worldDepth!=editor.curWorldDepth ) {
				wl.fieldsRender.visible = false;
				continue;
			}
			wl.fieldsRender.visible = editor.worldMode || editor.curLevel==l;
			if( editor.worldMode ) {
				wl.fieldsRender.alpha = getAlphaFromZoom(minZoom*0.5);
				if( wl.fieldsRender.alpha<=0 )
					wl.fieldsRender.visible = false;
			}

			if( !wl.fieldsRender.visible )
				continue;

			// Custom fields
			if( editor.worldMode ) {
				switch curWorld.worldLayout {
					case Free, GridVania:
						wl.fieldsRender.setScale( M.fmin(1/camera.adjustedZoom, M.fmin( l.pxWid/wl.fieldsRender.outerWidth, l.pxHei/wl.fieldsRender.outerHeight) ) );
						wl.fieldsRender.x = Std.int( l.worldCenterX - wl.fieldsRender.outerWidth*0.5*wl.fieldsRender.scaleX );
						wl.fieldsRender.y = Std.int( l.worldY + l.pxHei - wl.fieldsRender.outerHeight*wl.fieldsRender.scaleY );

					case LinearHorizontal:
						wl.fieldsRender.setScale( M.fmin(1/camera.adjustedZoom, l.pxWid/wl.fieldsRender.outerWidth ) );
						wl.fieldsRender.x = Std.int( l.worldCenterX - wl.fieldsRender.outerWidth*0.5*wl.fieldsRender.scaleX );
						wl.fieldsRender.y = Std.int( l.worldY + l.pxHei + 32 );

					case LinearVertical:
						wl.fieldsRender.setScale( M.fmin(1/camera.adjustedZoom, l.pxHei/wl.fieldsRender.outerHeight ) );
						wl.fieldsRender.x = Std.int( l.worldX + l.worldX+l.pxWid+32 );
						wl.fieldsRender.y = Std.int( l.worldCenterY - wl.fieldsRender.outerHeight*0.5*wl.fieldsRender.scaleY );
				}
			}
			else {
				wl.fieldsRender.setScale( M.fmin(1/camera.adjustedZoom, M.fmin( l.pxWid/wl.fieldsRender.outerWidth, l.pxHei/wl.fieldsRender.outerHeight) ) );
				wl.fieldsRender.x = Std.int( l.worldCenterX - wl.fieldsRender.outerWidth*0.5*wl.fieldsRender.scaleX );
				wl.fieldsRender.y = Std.int( l.worldY - fieldsPadding - wl.fieldsRender.outerHeight*wl.fieldsRender.scaleY );
				if( wl.identifier!=null && wl.identifier.visible )
					wl.fieldsRender.y -= wl.identifier.height * wl.identifier.scaleY + 3*settings.v.editorUiScale;
			}
		}
	}

	inline function getAlphaFromZoom(minZoom:Float) {
		return M.fmin( (camera.adjustedZoom-minZoom)/minZoom, 1 );
	}

	inline function updateAllLevelIdentifiers(refreshTexts:Bool) {
		for( l in editor.curWorld.levels )
			if( worldLevels.exists(l.uid) )
				updateLevelIdentifier(l, refreshTexts);
	}

	function renderGrids() {
		if( !editor.worldMode ) {
			smallGrid.visible = largeGrid.visible = false;
			return;
		}

		// Base level grid
		final minZoom = camera.pixelRatio*0.5;
		if( curWorld.worldLayout==Free && camera.adjustedZoom>=minZoom && settings.v.grid ) {
			smallGrid.clear();
			smallGrid.visible = true;
			smallGrid.lineStyle(camera.pixelRatio, worldLineColor, 0.5 * M.fmin( (camera.adjustedZoom-minZoom)/0.5, 1 ) );
			var g = project.getSmartLevelGridSize() * camera.adjustedZoom;
			// Verticals
			var off = root.x % g;
			for(i in 0...M.ceil(camera.width/g)) {
				smallGrid.moveTo(i*g+off, 0);
				smallGrid.lineTo(i*g+off, camera.height);
			}
			// Horizontals
			var off = root.y % g;
			for(i in 0...M.ceil(camera.height/g)) {
				smallGrid.moveTo(0, i*g+off);
				smallGrid.lineTo(camera.width, i*g+off);
			}
		}
		else
			smallGrid.visible = false;

		// World grid
		if( curWorld.worldLayout==GridVania && camera.adjustedZoom>=0.1 && settings.v.showDetails ) {
			largeGrid.clear();
			largeGrid.visible = true;
			largeGrid.lineStyle(camera.pixelRatio, worldLineColor, 0.1 + 0.2 * M.fmin( (camera.adjustedZoom-0.1)/0.3, 1 ) );
			var g = curWorld.worldGridWidth * camera.adjustedZoom;
			// Verticals
			var off =  root.x % g;
			for( i in 0...M.ceil(camera.width/g)+1 ) {
				largeGrid.moveTo(i*g+off, 0);
				largeGrid.lineTo(i*g+off, camera.height);
			}
			// Horizontals
			var g = curWorld.worldGridHeight * camera.adjustedZoom;
			var off =  root.y % g;
			for( i in 0...M.ceil(camera.height/g)+1 ) {
				largeGrid.moveTo(0, i*g+off);
				largeGrid.lineTo(camera.width, i*g+off);
			}
		}
		else
			largeGrid.visible = false;
	}

	inline function updateAxesPos() {
		if( !settings.v.showDetails || editor.gifMode ) {
			axeH.visible = axeV.visible = false;
		}
		else {
			switch curWorld.worldLayout {
				case Free, GridVania:
					axeH.visible = axeV.visible = true;

					// Horizontal
					axeH.y = root.y;
					axeH.scaleX = camera.iWidth;
					axeH.scaleY = 3*camera.pixelRatio;

					// Vertical
					axeV.x = root.x;
					axeV.scaleX = 3*camera.pixelRatio;
					axeV.scaleY = camera.iHeight;

				case LinearHorizontal, LinearVertical:
					axeH.visible = axeV.visible = false;
					return;
			}
		}
	}


	function renderWorldBounds() {
		App.LOG.render("Rendering world bounds...");
		var pad = project.defaultGridSize*3;
		var b = curWorld.getWorldBounds();
		worldBounds.clear();
		worldBounds.beginFill(project.bgColor, 0.8);
		worldBounds.drawRoundedRect(
			b.left-pad,
			b.top-pad,
			b.right-b.left+1+pad*2,
			b.bottom-b.top+1+pad*2,
			pad*0.5
		);
	}

	function updateCurrentHighlight() {
		final l = editor.curLevel;
		currentHighlight.visible = editor.worldMode && l.worldDepth==editor.curWorldDepth;
		if( !currentHighlight.visible )
			return;

		currentHighlight.clear();
		final thick = settings.v.showDetails ? 4 : 1;
		currentHighlight.lineStyle(thick/camera.adjustedZoom, 0xffcc00);
		var p = thick*0.5 / camera.adjustedZoom;
		currentHighlight.drawRect(l.worldX-p, l.worldY-p, l.pxWid+p*2, l.pxHei+p*2);
	}


	inline function refreshWorldLevelRect(l:data.Level) {
		var wl = getWorldLevel(l);
		if( wl!=null )
			wl.rect.useLevel(l);
	}


	function updateLevelVisibility(l:data.Level) {
		var wl = getWorldLevel(l);

		wl.bgWrapper.alpha = editor.worldMode ? 1 : 0.2;

		if( l.uid==editor.curLevelId && !editor.worldMode ) {
			// Hide current level in editor mode
			wl.outline.visible = false;
			wl.fadeMask.visible = false;
			wl.render.visible = false;
		}
		else if( editor.worldMode ) {
			// Show everything in world mode
			wl.bgWrapper.visible = wl.render.visible = wl.outline.visible = camera.isOnScreenLevel(l);
			wl.fadeMask.visible = false;
			wl.outline.alpha = 1;
		}
		else {
			// Fade other levels in editor mode
			var dist = editor.curLevel.getBoundsDist(l);
			wl.outline.alpha = 0.3;
			wl.outline.visible = camera.isOnScreenLevel(l);
			wl.fadeMask.visible = true;
			wl.render.visible = wl.outline.visible && dist<=300;
		}

		// Depths
		if( l.worldDepth!=editor.curWorldDepth ) {
			if( l.worldDepth<editor.curWorldDepth ) {
				// Above
				wl.outline.alpha*=0.45;
				wl.bgWrapper.visible = false;
				wl.render.visible = false;
				wl.fadeMask.visible = false;
				if( M.fabs(l.worldDepth-editor.curWorldDepth)>=2 )
					wl.outline.alpha*=0.3;
			}
			else {
				// Beneath
				wl.bgWrapper.alpha*=0.6;
				wl.render.alpha*=0.15;
				wl.outline.alpha*=0.2;
				if( M.fabs(l.worldDepth-editor.curWorldDepth)>=2 )
					wl.bgWrapper.alpha*=0.3;
			}
		}
		else {
			// Same world depth
			wl.render.alpha = 1;
		}
	}

	public function updateLayout() {
		var cur = editor.curLevel;

		// Level layout
		for( l in editor.curWorld.levels ) {
			if( !worldLevels.exists(l.uid) )
				continue;

			var wl = getWorldLevel(l);
			updateLevelVisibility(l);

			// Position
			wl.render.setPosition( l.worldX, l.worldY );
			wl.outline.setPosition( l.worldX, l.worldY );
			wl.bgWrapper.setPosition( l.worldX, l.worldY );
			wl.fadeMask.setPosition( l.worldX, l.worldY );
			wl.fadeMask.scaleX = l.pxWid;
			wl.fadeMask.scaleY = l.pxHei;
		}

		updateAllLevelIdentifiers(false);
		updateFieldsPos();
	}


	function removeWorldLevel(uid:Int) {
		if( worldLevels.exists(uid) ) {
			var wl = worldLevels.get(uid);
			wl.render.remove();
			wl.outline.remove();
			wl.fadeMask.remove();
			wl.bgWrapper.remove();
			wl.identifier.remove();
			if( wl.fieldsRender!=null )
				wl.fieldsRender.remove();
			worldLevels.remove(uid);
		}
	}


	function clearLevelRender(l:data.Level) {
		var wl = getWorldLevel(l);
		wl.bgWrapper.removeChildren();
		wl.outline.clear();
		wl.render.removeChildren();

		if( wl.edgeLayers!=null ) {
			for( td in wl.edgeLayers )
				td.clear();
			wl.edgeLayers = null;
		}
	}


	function renderFields(l:data.Level) {
		App.LOG.render('Rendering world level fields $l...');

		// Init fields wrapper
		var wl = getWorldLevel(l);
		if( wl.fieldsRender==null )
			wl.fieldsRender = {
				var f = new h2d.Flow(fieldsWrapper);
				f.layout = Vertical;
				f;
			}

		// Attach custom fields
		FieldInstanceRender.renderFields(
			project.defs.levelFields.map( fd->l.getFieldInstance(fd,true) ),
			l.getSmartColor(true),
			LevelCtx(l),
			wl.fieldsRender
		);

		updateFieldsPos();
	}


	function renderWorldLevel(l:data.Level) {
		if( l==null )
			throw "Unknown level";

		App.LOG.render('Rendering world level $l...');

		// Cleanup
		clearLevelRender(l);

		var wl = getWorldLevel(l);

		// Bg color
		var col = new h2d.Bitmap(h2d.Tile.fromColor(l.getBgColor()), wl.bgWrapper);
		col.scaleX = l.pxWid;
		col.scaleY = l.pxHei;

		// Bg image
		l.createBgTiledTexture(wl.bgWrapper);

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

		// Edge tiles render
		if( settings.v.nearbyTilesRenderingDist>0 && !editor.worldMode && l.touches(editor.curLevel) ) {
			var edgeDistPx = settings.getNearbyTilesRenderingDistPx();
			l.iterateLayerInstancesBottomToTop( (li)->{
				switch li.def.type {
					case IntGrid:
						if( !li.def.isAutoLayer() )
							return;

					case Entities:
						return;

					case Tiles:
					case AutoLayer:
				}

				var td = li.getTilesetDef();
				if( td==null || !td.isAtlasLoaded() )
					return;

				var edgeTg = new h2d.TileGroup(td.getAtlasTile(), wl.render);
				if( wl.edgeLayers==null )
					wl.edgeLayers = new Map();
				wl.edgeLayers.set(li.layerDefUid, edgeTg);
				// NOTE: layer offsets is already included in tiles render methods

				if( li.def.isAutoLayer() && li.autoTilesCache!=null ) {
					// Auto layer
					li.def.iterateActiveRulesInDisplayOrder( li, (r)->{
						if( li.autoTilesCache.exists( r.uid ) ) {
							for( allTiles in li.autoTilesCache.get( r.uid ) )
							for( tileInfos in allTiles ) {
								if( editor.curLevel.otherLevelCoordInBounds(l, tileInfos.x, tileInfos.y, edgeDistPx) ) {
									markCoordAsDone(li, Std.int(tileInfos.x/li.def.gridSize), Std.int(tileInfos.y/li.def.gridSize));
									LayerRender.renderAutoTileInfos(li, td, tileInfos, edgeTg);
								}
							}
						}
					});
				}
				else if( li.def.type==Tiles ) {
					// Classic tiles
					for(cy in 0...li.cHei)
					for(cx in 0...li.cWid) {
						if( editor.curLevel.otherLevelCoordInBounds(l, cx*li.def.gridSize, cy*li.def.gridSize, edgeDistPx) ) {
							markCoordAsDone(li,cx,cy);
							for( tileInf in li.getGridTileStack(cx,cy) )
								LayerRender.renderGridTile(li, td, tileInf, cx,cy, edgeTg);
						}
					}
				}
			} );

			updateEdgeLayersOpacity();
		}

		// Default simplified renders
		final alphaThreshold = 0.6;
		l.iterateLayerInstancesTopToBottom( li->{
			if( li.def.type==Entities || !li.def.renderInWorldView )
				return;

			if( li.def.isAutoLayer() && li.autoTilesCache==null ) {
				App.LOG.error("missing autoTilesCache in "+li);
				return;
			}

			var pixelGrid = new dn.heaps.PixelGrid(li.def.gridSize, li.cWid, li.cHei);
			wl.render.addChildAt(pixelGrid,0);
			pixelGrid.x = li.pxTotalOffsetX;
			pixelGrid.y = li.pxTotalOffsetY;

			// IntGrid/AutoLayer
			if( li.def.type==IntGrid && !li.def.isAutoLayer() ) {
				// Pure intGrid
				for(cy in 0...li.cHei)
				for(cx in 0...li.cWid) {
					if( !isCoordDone(li,cx,cy) && li.hasAnyGridValue(cx,cy) ) {
						markCoordAsDone(li, cx,cy);
						pixelGrid.setPixel(cx,cy, li.getIntGridColorAt(cx,cy) );
					}
				}
			}
			else {
				// Tiles base layer (autolayer or tiles)
				var td = li.getTilesetDef();
				if( td==null || !td.isAtlasLoaded() )
					return;

				if( li.def.isAutoLayer() ) {
					// Auto layer
					var c : dn.Col = 0x0;
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
									if( c.af>=alphaThreshold ) {
										markCoordAsDone(li,cx,cy);
										pixelGrid.setPixel24(cx,cy, c);
									}
								}
							}
						}
					});
				}
				else if( li.def.type==Tiles ) {
					// Classic tiles
					var c : dn.Col = 0x0;
					for(cy in 0...li.cHei)
					for(cx in 0...li.cWid)
						if( !isCoordDone(li,cx,cy) && li.hasAnyGridTile(cx,cy) ) {
							c = td.getAverageTileColor( li.getTopMostGridTile(cx,cy).tileId );
							if( c.af>=alphaThreshold ) {
								markCoordAsDone(li, cx,cy);
								pixelGrid.setPixel(cx,cy, c.withoutAlpha());
							}
						}
				}
			}
		});

		// Custom tile render override
		var t = l.getWorldTileFromFields();
		if( t!=null ) {
			var bmp = new h2d.Bitmap(t, wl.render);
			bmp.setScale( dn.heaps.Scaler.bestFit_f(t.width,t.height, l.pxWid,l.pxHei) );
		}

		updateLevelBounds(l);

		// Identifier
		wl.identifier.color.setColor( C.addAlphaF(0x464e79) );
		wl.identifier.alpha = 0.8;
		invalidateLevelIdentifier(l);
	}


	function updateEdgeLayersOpacity() {
		// Update edge layers opacity based on active one
		for(wl in worldLevels)
		for(li in editor.curLevel.layerInstances) {
			if( wl.edgeLayers==null || !wl.edgeLayers.exists(li.layerDefUid) )
				continue;

			if( li==editor.curLayerInstance )
				wl.edgeLayers.get(li.layerDefUid).alpha = li.def.displayOpacity;
			else
				wl.edgeLayers.get(li.layerDefUid).alpha = li.def.displayOpacity * li.def.inactiveOpacity;
		}
	}


	function updateLevelBounds(l:data.Level) {
		var wl = getWorldLevel(l);
		if( wl!=null ) {
			wl.outline.clear();
			if( !settings.v.showDetails )
				return;

			var thick = (l==editor.curLevel?3:2)*camera.pixelRatio / camera.adjustedZoom;
			var c : dn.Col = l.getSmartColor(false);

			var error = l.getFirstError();
			if( error!=NoError ) {
				thick*=4;
				c = 0xff0000;
			}

			var pad = 1;
			wl.outline.beginFill(c);
			wl.outline.drawRect(pad, pad, l.pxWid-pad*2, thick); // top
			wl.outline.drawRect(pad, l.pxHei-thick-pad, l.pxWid-pad*2, thick); // bottom
			wl.outline.drawRect(pad, pad, thick, l.pxHei-pad*2); // left
			wl.outline.drawRect(l.pxWid-thick-pad, pad, thick, l.pxHei-pad*2); // right
			wl.outline.endFill();
		}
	}


	function updateLevelIdentifier(l:data.Level, refreshTexts:Bool) {
		var wl = getWorldLevel(l);

		// Refresh text
		if( refreshTexts ) {
			wl.identifier.removeChildren();
			var tf = new h2d.Text(Assets.getRegularFont(), wl.identifier);
			tf.text = l.getDisplayIdentifier();
			tf.textColor = l.getSmartColor(false).toWhite(0.5);
			tf.x = 6;
			tf.y = -2;

			var error = l.getFirstError();
			if( error!=NoError ) {
				tf.textColor = 0xff0000;
				tf.text +=
					" <ERR: " + ( switch error {
						case NoError: '???';
						case InvalidEntityTag(ei): 'Incorrect tag: ${ei.def.identifier}';
						case InvalidEntityField(ei): 'Invalid field value: ${ei.def.identifier}';
						case InvalidBgImage: 'Bg image';
					}) + ">";
			}

			wl.identifier.width = tf.x*2 + tf.textWidth;
			wl.identifier.height = tf.textHeight;
		}

		// Visibility
		wl.identifier.visible = camera.adjustedZoom>=camera.getMinZoom() && settings.v.showDetails;
		if( l.worldDepth!=editor.curWorldDepth )
			wl.identifier.visible = false;

		if( !wl.identifier.visible )
			return;

		wl.identifier.alpha = l!=editor.curLevel || editor.worldMode ? getAlphaFromZoom( camera.getMinZoom()*0.8 ) : 1;

		// Scaling
		switch curWorld.worldLayout {
			case Free, GridVania:
				wl.identifier.setScale( M.fmin( l.pxWid / wl.identifier.width, 1/camera.adjustedZoom ) );

			case LinearHorizontal, LinearVertical:
				wl.identifier.setScale( 1/camera.adjustedZoom );
		}

		// Position
		wl.identifier.smooth = false;
		wl.identifier.rotation = 0;
		if( editor.worldMode ) {
			// Near level in world mode
			switch curWorld.worldLayout {
				case Free, GridVania:
					wl.identifier.x = Std.int( l.worldX + 2 );
					wl.identifier.y = Std.int( l.worldY + 2 );

				case LinearHorizontal:
					wl.identifier.x = Std.int( l.worldX + l.pxWid*0.3 );
					wl.identifier.y = Std.int( l.worldY - wl.identifier.height*wl.identifier.scaleY );
					wl.identifier.smooth = true;
					wl.identifier.rotation = -0.4;

				case LinearVertical:
					wl.identifier.x = Std.int( l.worldX - wl.identifier.width*wl.identifier.scaleX - 30 );
					wl.identifier.y = Std.int( l.worldY + l.pxHei*0.5 - wl.identifier.height*wl.identifier.scaleY*0.5 );
			}
		}
		else {
			// Above level when not in world mode
			wl.identifier.x = Std.int( l.worldX + l.pxWid*0.5 - wl.identifier.width*wl.identifier.scaleX*0.5 );
			wl.identifier.y = Std.int( l.worldY - wl.identifier.height*wl.identifier.scaleY - fieldsPadding );
		}

		// Color
		wl.identifier.color.setColor( l.getSmartColor(false).toBlack(0.3).withAlpha(l.useAutoIdentifier ? 0.4 : 1) );
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
		worldBounds.visible = editor.worldMode && editor.curWorld.levels.length>1;


		// Level invalidations
		if( !cd.hasSetS("levelRendersLock", 0.08) ) {
			// Check if a tileset is being loaded
			var waitingTileset = false;
			for(td in project.defs.tilesets)
				if( td.hasAtlasPointer() && !td.hasValidPixelData() && NT.fileExists(project.makeAbsoluteFilePath(td.relPath)) ) {
					waitingTileset = true;
					break;
				}

			// Check various level invalidations
			var limitRenders = 1;
			var limitOthers = 5;
			var limitBounds = 150;
			if( !waitingTileset ) {
				var l : data.Level = null;
				for( wl in worldLevels ) {
					if( wl.worldIid!=editor.curWorldIid )
						continue;

					if( !camera.isOnScreenWorldRect(wl.rect) )
						continue;

					l = editor.project.getLevelAnywhere(wl.uid);
					if( l==null ) {
						// Drop lost levels
						removeWorldLevel(wl.uid);
						continue;
					}

					// Level render
					if( wl.renderInvalidated && limitRenders-->0 ) {
						wl.renderInvalidated = false;
						renderWorldLevel(l);
						updateLayout();
					}

					// Bounds
					if( wl.boundsInvalidated && limitBounds-->0 ) {
						wl.boundsInvalidated = false;
						updateLevelBounds(l);
					}

					// Fields
					if( wl.fieldsInvalidated && ( editor.worldMode || editor.curLevel==l ) && limitOthers-->0 ) {
						wl.fieldsInvalidated = false;
						renderFields(l);
					}

					// Level identifiers
					if( wl.identifierInvalidated && limitOthers-->0 ) {
						wl.identifierInvalidated = false;
						updateLevelIdentifier( l, true );
					}
				}
			}
		}


		// Refresh elements which thickness is linked to camera zoom
		if( editor.worldMode && invalidatedCameraBasedRenders && !cd.hasSetS("boundsRender",0.15) ) {
			invalidatedCameraBasedRenders = false;
			renderGrids();
			updateCurrentHighlight();
		}
	}

}
