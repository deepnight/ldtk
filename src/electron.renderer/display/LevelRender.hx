package display;

typedef Bleep = {
	var spd : Float;
	var extraScale : Float;
	var g : h2d.Graphics;
}

class LevelRender extends dn.Process {
	public var editor(get,never) : Editor; inline function get_editor() return Editor.ME;
	public var camera(get,never) : display.Camera; inline function get_camera() return Editor.ME.camera;
	public var settings(get,never) : Settings; inline function get_settings() return App.ME.settings;

	var autoLayerRendering = true;

	var layersWrapper : h2d.Layers;

	/** <LayerDefUID, LayerRender> **/
	var layerRenders : Map<Int, LayerRender> = new Map();

	var bgColor : h2d.Bitmap;
	var bgImage : dn.heaps.TiledTexture;
	var bounds : h2d.Graphics;
	var boundsGlow : h2d.Graphics;
	var grid : h2d.Graphics;
	var rectBleeps : Array<Bleep> = [];
	public var temp : h2d.Graphics;

	// Invalidation system (ie. render calls)
	var allInvalidated = true;
	var uiAndBgInvalidated = false;
	var gridInvalidated = false;
	var layerInvalidations : Map<Int, { evaluateRules:Bool, left:Int, right:Int, top:Int, bottom:Int }> = new Map();


	public function new() {
		super(editor);

		editor.ge.addGlobalListener(onGlobalEvent);
		createRootInLayers(editor.root, Const.DP_MAIN);

		bgColor = new h2d.Bitmap();
		root.add(bgColor, Const.DP_BG);

		bgImage = new dn.heaps.TiledTexture(1, 1);
		root.add(bgImage, Const.DP_BG);

		bounds = new h2d.Graphics();
		root.add(bounds, Const.DP_UI);

		boundsGlow = new h2d.Graphics();
		root.add(boundsGlow, Const.DP_UI);

		grid = new h2d.Graphics();
		root.add(grid, Const.DP_UI);

		layersWrapper = new h2d.Layers();
		root.add(layersWrapper, Const.DP_MAIN);

		temp = new h2d.Graphics();
		root.add(temp, Const.DP_TOP);
	}

	override function onDispose() {
		super.onDispose();
		editor.ge.removeListener(onGlobalEvent);
	}

	function onGlobalEvent(e:GlobalEvent) {
		switch e {
			case LastChanceEnded:

			case AppSettingsChanged:
				invalidateAll();

			case WorldMode(active):
				if( active ) {
					// Remove hidden render
					for(l in layerRenders)
						l.dispose();
					layerRenders = new Map();
					grid.clear();

					// Stop process
					pause();
					root.visible = false;
				}
				else {
					// Resume
					root.visible = true;
					invalidateAll();
					resume();
				}

			case WorldSelected(w):
			case WorldCreated(w):
			case WorldRemoved(w):

			case WorldDepthSelected(worldDepth):

			case GridChanged(active):
				applyGridVisibility();

			case ShowDetailsChanged(active):
				applyAllLayersVisibility();
				applyGridVisibility();

			case ViewportChanged(_), WorldLevelMoved(_), WorldSettingsChanged:
				root.setScale( camera.adjustedZoom );
				root.x = M.round( editor.camera.width*0.5 - camera.levelX * camera.adjustedZoom );
				root.y = M.round( editor.camera.height*0.5 - camera.levelY * camera.adjustedZoom );
				updateGridPos();
				invalidateGrid();

			case ProjectSaved, BeforeProjectSaving:

			case ProjectSelected:
				renderAll();

			case ExternalEnumsLoaded(anyCriticalChange):
				invalidateAll();

			case ProjectSettingsChanged:
				invalidateUiAndBg();

			case LevelRestoredFromHistory(l):
				invalidateAll();
				editor.curLevel.invalidateCachedError();

			case LayerInstancesRestoredFromHistory(lis):
				for(li in lis)
					invalidateLayer(li, false);
				editor.curLevel.invalidateCachedError();

			case LevelSelected(l):
				invalidateAll();

			case LevelResized(l):
				for(li in l.layerInstances)
					if( li.def.isAutoLayer() )
						li.applyAllAutoLayerRules();
				invalidateAll();

			case LayerInstanceVisiblityChanged(li):
				applyLayerVisibility(li);

			case AutoLayerRenderingChanged:
				for(li in editor.curLevel.layerInstances)
					if( li.def.isAutoLayer() )
						invalidateLayer(li);

			case LayerInstanceTilesetChanged(cli):
				invalidateLayer(cli);

			case LayerInstanceSelected:
				applyAllLayersVisibility();
				invalidateUiAndBg();

			case LevelSettingsChanged(l):
				invalidateUiAndBg();

			case LevelJsonCacheInvalidated(l):

			case LayerDefRemoved(uid):
				if( layerRenders.exists(uid) ) {
					layerRenders.get(uid).dispose();
					layerRenders.remove(uid);
					for(li in editor.curLevel.layerInstances)
						if( !li.def.autoLayerRulesCanBeUsed() )
							invalidateLayer(li);
				}

			case LayerDefSorted:
				for( li in editor.curLevel.layerInstances ) {
					var depth = editor.project.defs.getLayerDepth(li.def);
					if( layerRenders.exists(li.layerDefUid) )
						layersWrapper.add( layerRenders.get(li.layerDefUid).root, depth );
				}

			case LayerDefChanged(defUid):
				invalidateLayer(defUid);
				renderGrid();

			case LayerDefConverted:
				invalidateAll();

			case LayerDefIntGridValuesSorted(defUid):

			case LayerDefIntGridValueRemoved(defUid,value,used):
				if( used )
					invalidateLayer(defUid);

			case LayerRuleChanged(r), LayerRuleAdded(r):
				var li = editor.curLevel.getLayerInstanceFromRule(r);
				li.applyAutoLayerRuleToAllLayer(r, true);
				invalidateLayer(li);

			case LayerRuleSeedChanged:
				invalidateLayer( editor.curLayerInstance );

			case LayerRuleSorted:
				invalidateLayer( editor.curLayerInstance );

			case LayerRuleRemoved(r):
				var li = editor.curLevel.getLayerInstanceFromRule(r);
				invalidateLayer( li==null ? editor.curLayerInstance : li );

			case LayerRuleGroupAdded(rg):
				if( rg.rules.length>0 )
					invalidateLayer(editor.curLayerInstance);

			case LayerRuleGroupRemoved(rg):
				editor.curLayerInstance.applyAllAutoLayerRules();
				invalidateLayer( editor.curLayerInstance );

			case LayerRuleGroupChanged(rg):
				invalidateLayer( editor.curLayerInstance );

			case LayerRuleGroupChangedActiveState(rg):
				invalidateLayer( editor.curLayerInstance );

			case LayerRuleGroupSorted:
				invalidateLayer( editor.curLayerInstance );

			case LayerRuleGroupCollapseChanged(rg):

			case LayerInstanceEditedByTool(li):

			case LayerInstanceChangedGlobally(li):
				invalidateLayer(li);

			case TilesetSelectionSaved(td):

			case TilesetDefPixelDataCacheRebuilt(td):

			case TilesetMetaDataChanged(td):

			case TilesetDefRemoved(td):
				invalidateAll();

			case TilesetImageLoaded(td, _), TilesetDefChanged(td):
				for(li in editor.curLevel.layerInstances)
					if( li.isUsingTileset(td) )
						invalidateLayer(li);

			case TilesetDefAdded(td):

			case TilesetDefSorted:

			case TilesetEnumChanged:
				if (settings.v.tileEnumOverlays)
					for( li in editor.curLevel.layerInstances)
						invalidateLayer(li);

			case EntityDefRemoved, EntityDefChanged, EntityDefSorted:
				for(li in editor.curLevel.layerInstances)
					if( li.def.type==Entities )
						invalidateLayer(li);

			case FieldDefAdded(_), FieldDefRemoved(_), FieldDefChanged(_), FieldDefSorted:
				for(li in editor.curLevel.layerInstances)
					if( li.def.type==Entities )
						invalidateLayer(li);

			case EnumDefRemoved, EnumDefChanged, EnumDefValueRemoved:
				for( li in editor.curLevel.layerInstances)
					if( settings.v.tileEnumOverlays || li.def.type==Entities )
						invalidateLayer(li);

			case LevelFieldInstanceChanged(l,fi):

			case EntityFieldInstanceChanged(ei,fi):
				invalidateLayer(ei._li);

			case EntityInstanceAdded(ei), EntityInstanceRemoved(ei), EntityInstanceChanged(ei):
				invalidateLayer(ei._li);

			case LevelAdded(l):

			case LevelRemoved(l):

			case LayerDefAdded:
				invalidateAll();

			case EntityDefAdded:

			case ToolOptionChanged:
			case ToolValueSelected:

			case EnumDefAdded:
			case EnumDefSorted:
		}

		for(lr in layerRenders)
			lr.onGlobalEvent(e);
	}

	public inline function isAutoLayerRenderingEnabled() {
		return autoLayerRendering;
	}

	public function setAutoLayerRendering(v:Bool) {
		autoLayerRendering = v;
		editor.ge.emit( AutoLayerRenderingChanged );
	}

	public inline function toggleAutoLayerRendering() {
		setAutoLayerRendering( !autoLayerRendering );
		return autoLayerRendering;
	}

	public inline function isLayerVisible(li:data.inst.LayerInstance, ignoreUserSettings=false) {
		if( li==null || !li.visible )
			return false;
		else if( !ignoreUserSettings && !settings.v.showDetails )
			return switch li.def.type {
				case IntGrid: li.def.isAutoLayer();
				case Entities: false;
				case Tiles, AutoLayer: true;
			}
		else
			return true;
	}

	public function toggleLayer(li:data.inst.LayerInstance) {
		li.visible = !li.visible;
		editor.ge.emit( LayerInstanceVisiblityChanged(li) );

		if( isLayerVisible(li) )
			invalidateLayer(li);
	}

	public function setLayerVisibility(li:data.inst.LayerInstance, v:Bool) {
		li.visible = v;
		editor.ge.emit( LayerInstanceVisiblityChanged(li) );
		editor.curLevelTimeline.saveLayerState(li);
		if( isLayerVisible(li) )
			invalidateLayer(li);
	}

	public inline function showLayer(li:data.inst.LayerInstance) {
		setLayerVisibility(li, true);
	}

	public inline function hideLayer(li:data.inst.LayerInstance) {
		setLayerVisibility(li, false);
	}

	public function bleepLevelRectPx(x:Float, y:Float, w:Float, h:Float, col:UInt, thickness=1, spd=1.0) : Bleep {
		var pad = 5;
		var g = new h2d.Graphics();
		rectBleeps.push({ g:g, spd:spd, extraScale:0 });
		g.lineStyle(thickness, col);
		g.drawRect(
			Std.int(-pad-w*0.5),
			Std.int(-pad-h*0.5),
			(w+pad*2),
			(h+pad*2)
		);
		g.setPosition(
			Std.int(x + w*0.5),
			Std.int(y + h*0.5)
		);
		root.add(g, Const.DP_UI);
		return rectBleeps[rectBleeps.length-1];
	}

	public inline function bleepLayerRectPx(li:data.inst.LayerInstance, x:Float, y:Float, w:Float, h:Float, col:UInt, thickness=1, spd=1.0) : Bleep {
		return bleepLevelRectPx(
			x+li.pxParallaxX, y+li.pxParallaxY,
			w*li.def.getScale(), h*li.def.getScale(),
			col, thickness, spd
		);
	}

	public inline function bleepLayerRectCase(li:data.inst.LayerInstance, cx:Int, cy:Int, cWid:Int, cHei:Int, col:UInt, thickness=1) : Bleep {
		return bleepLevelRectPx(
			cx*li.def.scaledGridSize + li.pxParallaxX, cy*li.def.scaledGridSize + li.pxParallaxY,
			cWid*li.def.scaledGridSize, cHei*li.def.scaledGridSize,
			col, thickness
		);
	}

	public function bleepDebug(li:data.inst.LayerInstance, cx:Int, cy:Int, c=0xffffff) {
		var g = new h2d.Graphics();
		root.add(g, Const.DP_UI);
		g.lineStyle(2, c, 1);
		g.drawCircle( 0,0, li.def.gridSize*0.5 );
		g.setPosition( M.round((cx+0.5)*li.def.gridSize), M.round((cy+0.5)*li.def.gridSize) );
		createChildProcess( p->{
			g.alpha-=tmod*0.04;
			if( g.alpha<=0 ) {
				g.remove();
				p.destroy();
			}
		});
	}

	public inline function bleepEntity(ei:data.inst.EntityInstance, ?overrideColor:Int, spd=1.0) : Bleep {
		return bleepLayerRectPx(
			ei._li,
			Std.int( (ei.x-ei.width*ei.def.pivotX) * ei._li.def.getScale() ),
			Std.int( (ei.y-ei.height*ei.def.pivotY) * ei._li.def.getScale() ),
			ei.width,
			ei.height,
			overrideColor!=null ? overrideColor : ei.getSmartColor(true),
			2, spd
		);
	}

	public inline function bleepPoint(x:Float, y:Float, col:UInt, thickness=2, spd=1.0) : Bleep {
		var g = new h2d.Graphics();
		rectBleeps.push({ g:g, spd:spd, extraScale:0 });
		g.lineStyle(thickness, col);
		g.drawCircle( 0,0, 16 );
		g.setPosition( M.round(x), M.round(y) );
		root.add(g, Const.DP_UI);
		return rectBleeps[rectBleeps.length-1];
	}


	function renderBg() {
		var level = editor.curLevel;

		var c = level.getBgColor();
		bgColor.tile = h2d.Tile.fromColor(c);
		bgColor.scaleX = editor.curLevel.pxWid;
		bgColor.scaleY = editor.curLevel.pxHei;

		var tt = level.createBgTiledTexture();
		if( tt!=null ) {
			bgImage.tile = tt.tile;
			bgImage.setPosition( tt.x, tt.y );
			bgImage.scaleX = tt.scaleX;
			bgImage.scaleY = tt.scaleY;
			bgImage.alignPivotX = tt.alignPivotX;
			bgImage.alignPivotY = tt.alignPivotY;
			bgImage.visible = true;
			bgImage.alpha = settings.v.singleLayerMode ? 0.2 : 1;
			bgImage.filter = settings.v.singleLayerMode ? getSingleLayerModeFilter() : null;
			bgImage.resize(tt.width, tt.height);
		}
		else {
			bgImage.tile = null;
			bgImage.visible = false;
		}
	}

	function renderBounds() {
		// Bounds
		bounds.clear();
		bounds.lineStyle(1, 0xffffff, 0.7);
		bounds.drawRect(0, 0, editor.curLevel.pxWid, editor.curLevel.pxHei);

		// Bounds glow/shadow
		boundsGlow.clear();
		boundsGlow.beginFill(0xff00ff);
		boundsGlow.drawRect(0, 0, editor.curLevel.pxWid, editor.curLevel.pxHei);
		var shadow = new h2d.filter.Glow( 0x0, 0.6, 128, true );
		shadow.knockout = true;
		boundsGlow.filter = shadow;
	}

	inline function applyGridVisibility() {
		grid.visible = settings.v.grid && settings.v.showDetails && !editor.worldMode && editor.curLayerInstance!=null;
	}

	inline function updateGridPos() {
		if( editor.curLayerInstance!=null ) {
			grid.x = camera.getParallaxOffsetX(editor.curLayerInstance);
			grid.y = camera.getParallaxOffsetY(editor.curLayerInstance);
			grid.setScale( editor.curLayerDef.getScale() );
		}
	}

	function renderGrid() {
		grid.clear();
		applyGridVisibility();

		if( editor.curLayerInstance==null )
			return;

		var col = C.getPerceivedLuminosityInt( editor.project.bgColor) >= 0.8 ? 0x0 : 0xffffff;

		var li = editor.curLayerInstance;
		var level = editor.curLevel;

		// Main grid
		var size = li.def.gridSize;
		grid.lineStyle(1/camera.adjustedZoom, col, 0.07);
		var x = 0;
		for( cx in 0...editor.curLayerInstance.cWid+1 ) { // Verticals
			x = cx*size + li.pxTotalOffsetX;
			if( x<0 || x>level.pxWid )
				continue;

			grid.moveTo( x, M.fmax(0,li.pxTotalOffsetY) );
			grid.lineTo( x, M.fmin(li.cHei*size, level.pxHei) );
		}
		var y = 0;
		for( cy in 0...editor.curLayerInstance.cHei+1 ) { // Horizontals
			y = cy*size + li.pxTotalOffsetY;
			if( y<0 || y>level.pxHei)
				continue;

			grid.moveTo( M.fmax(0,li.pxTotalOffsetX), y );
			grid.lineTo( M.fmin(li.cWid*size, level.pxWid), y );
		}


		// Guide grid (verticals)
		if( editor.curLayerDef.guideGridWid>1 ) {
			var size = li.def.guideGridWid;
			grid.lineStyle(1/camera.adjustedZoom, col, 0.33);

			var cWid = Std.int(editor.curLayerInstance.pxWid/size)+1;

			var x = 0;
			for( cx in 0...cWid ) { // Verticals
				x = cx*size + li.pxTotalOffsetX;
				if( x<0 || x>level.pxWid )
					continue;

				grid.moveTo( x, M.fmax(0,li.pxTotalOffsetY) );
				grid.lineTo( x, level.pxHei+li.pxTotalOffsetY );
			}
		}


		// Guide grid (horizontals)
		if( editor.curLayerDef.guideGridHei>1 ) {
			var size = li.def.guideGridHei;
			grid.lineStyle(1/camera.adjustedZoom, col, 0.33);

			var cHei = Std.int(editor.curLayerInstance.pxHei/size)+1;

			var y = 0;
			for( cy in 0...cHei+1 ) { // Horizontals
				y = cy*size + li.pxTotalOffsetY;
				if( y<0 || y>level.pxHei)
					continue;

				grid.moveTo( M.fmax(0,li.pxTotalOffsetX), y );
				grid.lineTo( level.pxWid+li.pxTotalOffsetX, y );
			}
		}

		// Horizontal guide lines
		// grid.lineStyle(1, 0xffcc00, 0.5);
		// for(v in li.def.guidesH) {
		// 	grid.moveTo( M.fmax(0,li.pxTotalOffsetX), v+li.pxTotalOffsetY );
		// 	grid.lineTo( M.fmin(li.cWid*size, level.pxWid), v+li.pxTotalOffsetY );
		// }

		// Vertical guide lines
		// grid.lineStyle(1, 0xffcc00, 0.5);
		// for(v in li.def.guidesV) {
		// 	grid.moveTo( v+li.pxTotalOffsetX, M.fmax(0,li.pxTotalOffsetY) );
		// 	grid.lineTo( v+li.pxTotalOffsetX, M.fmin(li.cHei*size, level.pxHei) );
		// }

		updateGridPos();
	}


	public function renderAll() {
		allInvalidated = false;

		clearTemp();
		renderBounds();
		renderGrid();
		renderBg();

		for(ld in editor.project.defs.layers)
			renderLayer( editor.curLevel.getLayerInstance(ld) );
	}

	public inline function clearTemp() {
		temp.clear();
		temp.alpha = 1;
	}


	function renderLayer(li:data.inst.LayerInstance) {
		layerInvalidations.remove(li.layerDefUid);

		if( !layerRenders.exists(li.layerDefUid) ) {
			// Create new render
			var lr = new LayerRender();
			lr.render(li, autoLayerRendering);
			layerRenders.set(li.layerDefUid, lr);
			layersWrapper.add( lr.root, editor.project.defs.getLayerDepth(li.def) );
		}
		else {
			// Refresh render
			var lr = layerRenders.get(li.layerDefUid);
			lr.render(li, autoLayerRendering);
		}

		applyLayerVisibility(li);
	}


	function applyLayerVisibility(li:data.inst.LayerInstance) {
		var lr = layerRenders.get(li.layerDefUid);
		if( lr==null )
			return;

		lr.root.visible = isLayerVisible(li);
		lr.root.alpha = li.def.displayOpacity * ( !settings.v.singleLayerMode || li==editor.curLayerInstance ? 1 : 0.05 );
		lr.root.filter = !settings.v.singleLayerMode || li==editor.curLayerInstance ? null : getSingleLayerModeFilter();
		if( li!=editor.curLayerInstance )
			lr.root.alpha *= li.def.inactiveOpacity;
	}

	function getSingleLayerModeFilter() : h2d.filter.Filter {
		return new h2d.filter.Group([
			C.getColorizeFilterH2d(0x8c99c1, 1),
			new h2d.filter.Blur(8),
		]);
	}


	@:allow(page.Editor)
	function applyAllLayersVisibility() {
		for(ld in editor.project.defs.layers) {
			var li = editor.curLevel.getLayerInstance(ld);
			applyLayerVisibility(li);
		}
	}

	public inline function invalidateLayer(?li:data.inst.LayerInstance, ?layerDefUid:Int, evaluateRules=true) {
		if( li==null )
			li = editor.curLevel.getLayerInstance(layerDefUid);
		layerInvalidations.set( li.layerDefUid, { evaluateRules:evaluateRules, left:0, right:li.cWid-1, top:0, bottom:li.cHei-1 } );

		if( li.def.type==IntGrid )
			for(l in editor.curLevel.layerInstances)
				if( l.def.type==AutoLayer && l.def.autoSourceLayerDefUid==li.def.uid )
					invalidateLayer(l);
	}

	public inline function invalidateLayerArea(li:data.inst.LayerInstance, left:Int, right:Int, top:Int, bottom:Int, evaluateRules=true) {
		if( layerInvalidations.exists(li.layerDefUid) ) {
			var bounds = layerInvalidations.get(li.layerDefUid);
			bounds.left = M.imin(bounds.left, left);
			bounds.right = M.imax(bounds.right, right);
			bounds.top = M.imin(bounds.top, top);
			bounds.bottom = M.imax(bounds.bottom, bottom);
			bounds.evaluateRules = evaluateRules;
		}
		else
			layerInvalidations.set( li.layerDefUid, { evaluateRules:evaluateRules, left:left, right:right, top:top, bottom:bottom } );

		// Invalidate linked auto-layers
		if( li.def.type==IntGrid )
			for(other in editor.curLevel.layerInstances)
				if( other.def.type==AutoLayer && other.def.autoSourceLayerDefUid==li.layerDefUid )
					invalidateLayerArea(other, left, right, top, bottom);
	}

	public inline function invalidateUiAndBg() {
		uiAndBgInvalidated = true;
	}

	public inline function invalidateGrid() {
		gridInvalidated = true;
	}

	public inline function invalidateAll() {
		allInvalidated = true;
	}


	public function applyInvalidations() {
		if( allInvalidated ) {
			// Full
			renderAll();
			App.LOG.warning("Full level render requested");
		}
		else {
			// UI & bg elements
			if( uiAndBgInvalidated ) {
				renderBg();
				renderBounds();
				uiAndBgInvalidated = false;
				App.LOG.render("Rendered level UI");
			}

			if( gridInvalidated && !cd.hasSetS("gridRenderLock",0.2) )
				renderGrid();

			// Layers
			for( li in editor.curLevel.layerInstances )
				if( layerInvalidations.exists(li.layerDefUid) ) {
					var inv = layerInvalidations.get(li.layerDefUid);
					if( li.def.isAutoLayer() && inv.evaluateRules )
						li.applyAllAutoLayerRulesAt( inv.left, inv.top, inv.right-inv.left+1, inv.bottom-inv.top+1 );
					renderLayer(li);
				}
		}
	}



	override function postUpdate() {
		super.postUpdate();

		// Error bleeps
		if( !cd.has("errorBleeps") )
			switch editor.curLevel.getFirstError() {
				case NoError:
					cd.unset("errorBleeps");

				case InvalidEntityTag(ei), InvalidEntityField(ei):
					if( !ui.EntityInstanceEditor.existsFor(ei) ) {
						var b = bleepEntity(ei, 0xff0000, 0.4);
						b.extraScale = 1;
						cd.setS("errorBleeps",0.7);
					}

				case InvalidBgImage:
			}

		// Fade-out temporary bleeps
		var i = 0;
		while( i<rectBleeps.length ) {
			var b = rectBleeps[i];
			b.g.alpha -= 0.064 * tmod * ( b.spd!=null ? b.spd : 1 );
			b.g.setScale( (b.extraScale + 1.6) - (b.extraScale + 0.6)*(1-b.g.alpha) );
			if( b.g.alpha<=0 ) {
				b.g.remove();
				rectBleeps.splice(i,1);
			}
			else
				i++;
		}

		applyInvalidations();
		applyGridVisibility();
	}

}
