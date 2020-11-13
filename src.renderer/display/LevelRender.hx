package display;

class LevelRender extends dn.Process {
	static var WORLD_LEVEL_SCALE = 0.1;
	static var MIN_ZOOM = 0.2;
	static var MAX_ZOOM = 32;
	static var MAX_FOCUS_PADDING_X = 450;
	static var MAX_FOCUS_PADDING_Y = 400;
	static var FIELD_TEXT_SCALE = 0.666;

	public var editor(get,never) : Editor; inline function get_editor() return Editor.ME;
	public var settings(get,never) : AppSettings; inline function get_settings() return App.ME.settings;

	public var focusLevelX(default,set) : Float;
	public var focusLevelY(default,set) : Float;
	var targetLevelX: Null<Float>;
	var targetLevelY: Null<Float>;
	public var adjustedZoom(get,set) : Float;
	var rawZoom : Float;
	var worldZoom = 0.;
	var isFit = false;

	/** <LayerDefUID, Bool> **/
	var autoLayerRendering : Map<Int,Bool> = new Map();

	/** <LayerDefUID, Bool> **/
	var layerVis : Map<Int,Bool> = new Map();

	var layersWrapper : h2d.Layers;
	/** <LayerDefUID, h2d.Object> **/
	var layerRenders : Map<Int,h2d.Object> = new Map();

	var worldLevels : Map<Int, { wrapper:h2d.Object, render:h2d.Graphics }> = new Map();
	var worldBg : { wrapper:h2d.Object, col:h2d.Bitmap, tex:dn.heaps.TiledTexture };
	var worldWrapper : h2d.Object;
	var bounds : h2d.Graphics;
	var boundsGlow : h2d.Graphics;
	var grid : h2d.Graphics;
	var rectBleeps : Array<h2d.Object> = [];

	public var temp : h2d.Graphics;

	// Invalidation system (ie. render calls)
	var allInvalidated = true;
	var bgInvalidated = false;
	var layerInvalidations : Map<Int, { left:Int, right:Int, top:Int, bottom:Int }> = new Map();
	var worldLevelsInvalidations : Map<Int,Bool> = new Map();


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

		worldWrapper = new h2d.Graphics();
		root.add(worldWrapper, Const.DP_MAIN);

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

		focusLevelX = 0;
		focusLevelY = 0;
		adjustedZoom = 3;
	}

	public function setFocus(x,y) {
		focusLevelX = x;
		focusLevelY = y;
	}

	public function fit() {
		cancelAutoScrolling();
		var wasFit = isFit;
		focusLevelX = editor.curLevel.pxWid*0.5;
		focusLevelY = editor.curLevel.pxHei*0.5;

		var old = rawZoom;
		var pad = 100 * js.Browser.window.devicePixelRatio;
		adjustedZoom = M.fmin(
			editor.canvasWid() / ( editor.curLevel.pxWid + pad ),
			editor.canvasHei() / ( editor.curLevel.pxHei + pad )
		);

		// Fit closer if repeated
		if( wasFit ) {
			var pad = 8 * js.Browser.window.devicePixelRatio;
			adjustedZoom = M.fmin(
				editor.canvasWid() / ( editor.curLevel.pxWid + pad ),
				editor.canvasHei() / ( editor.curLevel.pxHei + pad )
			);
		}

		isFit = true;
	}

	inline function set_focusLevelX(v) {
		isFit = false;
		focusLevelX = editor.curLevelId==null || editor.worldMode
			? v
			: M.fclamp( v, -MAX_FOCUS_PADDING_X/adjustedZoom, editor.curLevel.pxWid+MAX_FOCUS_PADDING_X/adjustedZoom );
		editor.ge.emitAtTheEndOfFrame( ViewportChanged );
		return focusLevelX;
	}

	inline function set_focusLevelY(v) {
		isFit = false;
		focusLevelY = editor.curLevelId==null || editor.worldMode
			? v
			: M.fclamp( v, -MAX_FOCUS_PADDING_Y/adjustedZoom, editor.curLevel.pxHei+MAX_FOCUS_PADDING_Y/adjustedZoom );
		editor.ge.emitAtTheEndOfFrame( ViewportChanged );
		return focusLevelY;
	}

	public function autoScrollTo(levelX:Float,levelY:Float) {
		targetLevelX = levelX;
		targetLevelY = levelY;
	}

	public inline function autoScrollToLevel(l:data.Level) {
		autoScrollTo( l.pxWid*0.5, l.pxHei*0.5 );
	}

	public inline function cancelAutoScrolling() {
		targetLevelX = targetLevelY = null;
	}

	inline function set_adjustedZoom(v) {
		isFit = false;
		rawZoom = M.fclamp(v, MIN_ZOOM, MAX_ZOOM);
		editor.ge.emitAtTheEndOfFrame(ViewportChanged);
		return rawZoom;
	}

	inline function get_adjustedZoom() {
		// reduces tile flickering (#71)
		return
			( rawZoom<=js.Browser.window.devicePixelRatio ? rawZoom : M.round(rawZoom*2)/2 )
			+ worldZoom*-0.3*rawZoom;
	}

	public function deltaZoom(delta:Float) {
		isFit = false;
		cancelAutoScrolling();
		rawZoom += delta * rawZoom;
		rawZoom = M.fclamp(rawZoom, MIN_ZOOM, MAX_ZOOM);
	}

	public inline function levelToUiX(x:Float) {
		return M.round( x*adjustedZoom + root.x );
	}

	public inline function levelToUiY(y:Float) {
		return M.round( y*adjustedZoom + root.y );
	}

	override function onDispose() {
		super.onDispose();
		worldBg.wrapper.remove();
		editor.ge.removeListener(onGlobalEvent);
	}

	override function onResize() {
		super.onResize();
		renderWorldBg();
	}

	function onGlobalEvent(e:GlobalEvent) {
		switch e {
			case ViewportChanged:
				root.setScale(adjustedZoom);
				root.x = M.round( editor.canvasWid()*0.5 - focusLevelX * adjustedZoom );
				root.y = M.round( editor.canvasHei()*0.5 - focusLevelY * adjustedZoom );

			case ProjectSaved, BeforeProjectSaving:

			case ProjectSelected:
				renderAll();
				fit();
				resetWorldRender();
				updateWorld();

			case ProjectSettingsChanged:
				invalidateBg();
				renderWorldBg();

			case LevelRestoredFromHistory(l):
				invalidateAll();
				invalidateWorldLevel(l);

			case LayerInstanceRestoredFromHistory(li):
				invalidateLayer(li);

			case LevelSelected(l):
				renderAll();
				// fit();
				updateWorld();

			case LevelResized(l):
				invalidateAll();
				invalidateWorldLevel(l);

			case LayerInstanceVisiblityChanged(li):
				applyLayerVisibility(li);

			case LayerInstanceAutoRenderingChanged(li):
				invalidateLayer(li);

			case LayerInstanceSelected:
				applyAllLayersVisibility();
				invalidateBg();

			case LevelSettingsChanged(l):
				invalidateBg();
				invalidateWorldLevel(l);

			case LayerDefRemoved(uid):
				if( layerRenders.exists(uid) ) {
					layerRenders.get(uid).remove();
					layerRenders.remove(uid);
					for(li in editor.curLevel.layerInstances)
						if( !li.def.autoLayerRulesCanBeUsed() )
							invalidateLayer(li);
				}

			case LayerDefSorted:
				for( li in editor.curLevel.layerInstances ) {
					var depth = editor.project.defs.getLayerDepth(li.def);
					if( layerRenders.exists(li.layerDefUid) )
						layersWrapper.add( layerRenders.get(li.layerDefUid), depth );
				}

			case LayerDefChanged, LayerDefConverted:
				invalidateAll();

			case LayerRuleChanged(r), LayerRuleAdded(r):
				var li = editor.curLevel.getLayerInstanceFromRule(r);
				li.applyAutoLayerRuleToAllLayer(r);
				invalidateLayer(li);

			case LayerRuleSeedChanged:
				invalidateLayer( editor.curLayerInstance );

			case LayerRuleSorted:
				invalidateLayer( editor.curLayerInstance );

			case LayerRuleRemoved(r):
				var li = editor.curLevel.getLayerInstanceFromRule(r);
				invalidateLayer( li==null ? editor.curLayerInstance : li );

			case LayerRuleGroupAdded:

			case LayerRuleGroupRemoved(rg):
				editor.curLayerInstance.applyAllAutoLayerRules();
				invalidateLayer( editor.curLayerInstance );

			case LayerRuleGroupChanged(rg):
				invalidateLayer( editor.curLayerInstance );

			case LayerRuleGroupChangedActiveState(rg):
				invalidateLayer( editor.curLayerInstance );

			case LayerRuleGroupSorted:
				invalidateLayer( editor.curLayerInstance );

			case LayerRuleGroupCollapseChanged:

			case LayerInstanceChanged:

			case TilesetSelectionSaved(td):

			case TilesetDefPixelDataCacheRebuilt(td):
				resetWorldRender();

			case TilesetDefRemoved(td):
				invalidateAll();

			case TilesetDefChanged(td):
				for(li in editor.curLevel.layerInstances)
					if( li.def.isUsingTileset(td) )
						invalidateLayer(li);

			case TilesetDefAdded(td):

			case EntityDefRemoved, EntityDefChanged, EntityDefSorted:
				for(li in editor.curLevel.layerInstances)
					if( li.def.type==Entities )
						invalidateLayer(li);

			case EntityFieldAdded(ed), EntityFieldRemoved(ed), EntityFieldDefChanged(ed):
				if( editor.curLayerInstance!=null ) {
					var li = editor.curLevel.getLayerInstanceFromEntity(ed);
					invalidateLayer( li==null ? editor.curLayerInstance : li );
				}

			case EnumDefRemoved, EnumDefChanged, EnumDefValueRemoved:
				for(li in editor.curLevel.layerInstances)
					if( li.def.type==Entities )
						invalidateLayer(li);

			case EntityInstanceAdded(ei), EntityInstanceRemoved(ei), EntityInstanceChanged(ei), EntityInstanceFieldChanged(ei):
				var li = editor.curLevel.getLayerInstanceFromEntity(ei);
				invalidateLayer( li==null ? editor.curLayerInstance : li );

			case LevelAdded(l):
				invalidateWorldLevel(l);
				updateWorld();

			case LevelRemoved(l):
				updateWorld();

			case LevelSorted:
			case LayerDefAdded:

			case EntityDefAdded:
			case EntityFieldSorted:

			case ToolOptionChanged:

			case EnumDefAdded:
			case EnumDefSorted:
		}
	}

	public inline function autoLayerRenderingEnabled(li:data.inst.LayerInstance) {
		if( li==null || !li.def.isAutoLayer() )
			return false;

		return ( !autoLayerRendering.exists(li.layerDefUid) || autoLayerRendering.get(li.layerDefUid)==true );
	}

	public function setAutoLayerRendering(li:data.inst.LayerInstance, v:Bool) {
		if( li==null || !li.def.isAutoLayer() )
			return;

		autoLayerRendering.set(li.layerDefUid, v);
		editor.ge.emit( LayerInstanceAutoRenderingChanged(li) );
	}

	public function toggleAutoLayerRendering(li:data.inst.LayerInstance) {
		if( li!=null && li.def.isAutoLayer() )
			setAutoLayerRendering( li, !autoLayerRenderingEnabled(li) );
	}

	public inline function isLayerVisible(l:data.inst.LayerInstance) {
		return l!=null && ( !layerVis.exists(l.layerDefUid) || layerVis.get(l.layerDefUid)==true );
	}

	public function toggleLayer(li:data.inst.LayerInstance) {
		layerVis.set(li.layerDefUid, !isLayerVisible(li));
		editor.ge.emit( LayerInstanceVisiblityChanged(li) );

		if( isLayerVisible(li) )
			invalidateLayer(li);
	}

	public function showLayer(li:data.inst.LayerInstance) {
		layerVis.set(li.layerDefUid, true);
		editor.ge.emit( LayerInstanceVisiblityChanged(li) );
	}

	public function hideLayer(li:data.inst.LayerInstance) {
		layerVis.set(li.layerDefUid, false);
		editor.ge.emit( LayerInstanceVisiblityChanged(li) );
	}

	public function bleepRectPx(x:Int, y:Int, w:Int, h:Int, col:UInt, thickness=1) {
		var pad = 5;
		var g = new h2d.Graphics();
		rectBleeps.push(g);
		g.lineStyle(thickness, col);
		g.drawRect( Std.int(-pad-w*0.5), Std.int(-pad-h*0.5), w+pad*2, h+pad*2 );
		g.setPosition(
			Std.int(x+w*0.5) + editor.curLayerInstance.pxTotalOffsetX,
			Std.int(y+h*0.5) + editor.curLayerInstance.pxTotalOffsetY
		);
		root.add(g, Const.DP_UI);
	}

	public inline function bleepRectCase(cx:Int, cy:Int, cWid:Int, cHei:Int, col:UInt, thickness=1) {
		var li = editor.curLayerInstance;
		bleepRectPx(
			cx*li.def.gridSize,
			cy*li.def.gridSize,
			cWid*li.def.gridSize,
			cHei*li.def.gridSize,
			col, 2
		);
	}

	public inline function bleepHistoryBounds(layerId:Int, bounds:HistoryStateBounds, col:UInt) {
		bleepRectPx(bounds.x, bounds.y, bounds.wid, bounds.hei, col, 2);
	}
	public inline function bleepEntity(ei:data.inst.EntityInstance) {
		bleepRectPx(
			Std.int( ei.x-ei.def.width*ei.def.pivotX ),
			Std.int( ei.y-ei.def.height*ei.def.pivotY ),
			ei.def.width,
			ei.def.height,
			ei.getSmartColor(true), 2
		);
	}

	public inline function bleepPoint(x:Float, y:Float, col:UInt, thickness=2) {
		var g = new h2d.Graphics();
		rectBleeps.push(g);
		g.lineStyle(thickness, col);
		g.drawCircle( 0,0, 16 );
		g.setPosition( M.round(x), M.round(y) );
		root.add(g, Const.DP_UI);
	}



	public inline function invalidateWorldLevel(l:data.Level) {
		worldLevelsInvalidations.set(l.uid, true);
	}

	public function resetWorldRender() {
		App.LOG.render("Reset world render");
		for(e in worldLevels)
			e.wrapper.remove();
		worldLevels = new Map();
		worldWrapper.removeChildren();

		for(l in editor.project.levels)
			invalidateWorldLevel(l);
	}

	function renderWorldBg() {
		worldBg.tex.resize( Std.int(editor.canvasWid()), Std.int(editor.canvasHei()) );
		worldBg.col.tile = h2d.Tile.fromColor( C.interpolateInt(editor.project.bgColor, 0x8187bd, 0.85) );
		worldBg.col.scaleX = editor.canvasWid();
		worldBg.col.scaleY = editor.canvasHei();
	}

	public function updateWorld() {
		worldWrapper.x = -editor.curLevel.worldX;
		worldWrapper.y = -editor.curLevel.worldY;

		for( l in editor.project.levels )
			if( worldLevels.exists(l.uid) ) {
				var e = worldLevels.get(l.uid);
				if( l.uid==editor.curLevelId && !editor.worldMode )
					e.wrapper.visible = false;
				else {
					e.wrapper.setPosition( l.worldX, l.worldY );
					e.wrapper.visible = true;
				}

				e.wrapper.alpha = editor.worldMode ? 1 : 0.2;
			}

	}

	function renderWorldLevel(l:data.Level) {
		if( l==null )
			throw "Unknown level";

		App.LOG.render("Rendered WorldLevel "+l);

		// Cleanup
		worldLevelsInvalidations.remove(l.uid);
		if( worldLevels.exists(l.uid) )
			worldLevels.get(l.uid).wrapper.remove();

		var scale = WORLD_LEVEL_SCALE;
		var wrapper = new h2d.Object(worldWrapper);

		var render = new h2d.Graphics(wrapper);
		render.setScale(1/scale);

		worldLevels.set(l.uid, { wrapper:wrapper, render:render });

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

		// Render level

		for(li in l.layerInstances) {
			if( li.def.type==Entities )
				continue;

			var g = li.def.gridSize*scale;

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
				for(cy in 0...li.cHei)
				for(cx in 0...li.cWid) {
					if( !isCoordDone(li,cx,cy) && li.hasAnyGridValue(cx,cy) ) {
						markCoordAsDone(li, cx,cy);
						render.beginFill( li.getIntGridColorAt(cx,cy) );
						render.drawRect(
							li.pxTotalOffsetX*scale + cx*g,
							li.pxTotalOffsetY*scale + cy*g,
							g, g
						);
						render.endFill();
					}
				}
			}
			else if( li.def.type==Tiles ) {
				// Classic tiles
				var td = editor.project.defs.getTilesetDef(li.def.tilesetDefUid);
				for(cy in 0...li.cHei)
				for(cx in 0...li.cWid) {
					if( !isCoordDone(li,cx,cy) && li.hasAnyGridTile(cx,cy) ) {
						markCoordAsDone(li, cx,cy);
						render.beginFill( td.getAverageTileColor( li.getTopMostGridTile(cx,cy).tileId ) );
						render.drawRect(
							li.pxTotalOffsetX*scale + cx*g,
							li.pxTotalOffsetY*scale + cy*g,
							g, g
						);
					}
				}
			}
		}

		// Bounds
		var g = new h2d.Graphics(wrapper);
		g.lineStyle(3, l==editor.curLevel ? 0xffffff : 0xffcc00, 1);
		g.drawRect(0, 0, l.pxWid, l.pxHei);

		// Identifier
		var bg = new h2d.ScaleGrid(Assets.elements.getTile("fieldBg"), 2, 2, wrapper );
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


	function renderBounds() {
		bgInvalidated = false;

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

	public inline function applyGridVisibility() {
		grid.visible = settings.grid && !editor.worldMode;
	}

	function renderGrid() {
		bgInvalidated = false;
		grid.clear();
		applyGridVisibility();

		if( editor.curLayerInstance==null )
			return;

		var col = C.getPerceivedLuminosityInt( editor.project.bgColor) >= 0.8 ? 0x0 : 0xffffff;

		var li = editor.curLayerInstance;
		var level = editor.curLevel;
		grid.lineStyle(1, col, 0.07);

		// Verticals
		var x = 0;
		for( cx in 0...editor.curLayerInstance.cWid+1 ) {
			x = cx*li.def.gridSize + li.pxTotalOffsetX;
			if( x<0 || x>=level.pxWid )
				continue;

			grid.moveTo( x, M.fmax(0,li.pxTotalOffsetY) );
			grid.lineTo( x, M.fmin(li.cHei*li.def.gridSize, level.pxHei) );
		}
		// Horizontals
		var y = 0;
		for( cy in 0...editor.curLayerInstance.cHei+1 ) {
			y = cy*li.def.gridSize + li.pxTotalOffsetY;
			if( y<0 || y>=level.pxHei)
				continue;

			grid.moveTo( M.fmax(0,li.pxTotalOffsetX), y );
			grid.lineTo( M.fmin(li.cWid*li.def.gridSize, level.pxWid), y );
		}
	}


	public function renderAll() {
		allInvalidated = false;

		clearTemp();
		renderBounds();
		renderGrid();

		for(ld in editor.project.defs.layers) {
			var li = editor.curLevel.getLayerInstance(ld);
			// if( li.def.isAutoLayer() )
			// 	li.applyAllAutoLayerRules();
			renderLayer(li);
		}
	}

	public inline function clearTemp() {
		temp.clear();
	}


	function renderLayer(li:data.inst.LayerInstance) {
		layerInvalidations.remove(li.layerDefUid);

		// Create wrapper
		if( layerRenders.exists(li.layerDefUid) )
			layerRenders.get(li.layerDefUid).remove();

		var wrapper = new h2d.Object();
		wrapper.x = li.pxTotalOffsetX;
		wrapper.y = li.pxTotalOffsetY;

		// Register it
		layerRenders.set(li.layerDefUid, wrapper);
		var depth = editor.project.defs.getLayerDepth(li.def);
		layersWrapper.add( wrapper, depth );

		// Render
		switch li.def.type {
		case IntGrid, AutoLayer:
			var g = new h2d.Graphics(wrapper);

			// var doneCoords = new Map();

			if( li.def.isAutoLayer() && li.def.autoTilesetDefUid!=null && autoLayerRenderingEnabled(li) ) {
				// Auto-layer tiles
				var td = editor.project.defs.getTilesetDef( li.def.autoTilesetDefUid );
				var tg = new h2d.TileGroup( td.getAtlasTile(), wrapper);

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

				// Default render when no rule match here
				// if( li.def.type==IntGrid )
				// 	for(cy in 0...li.cHei)
				// 	for(cx in 0...li.cWid) {
				// 		if( doneCoords.exists(li.coordId(cx,cy)) || li.getIntGrid(cx,cy)<0 )
				// 			continue;
				// 		g.lineStyle(1, li.getIntGridColorAt(cx,cy), 0.6 );
				// 		g.drawRect(cx*li.def.gridSize+2, cy*li.def.gridSize+2, li.def.gridSize-4, li.def.gridSize-4);
				// 	}
			}
			else if( li.def.type==IntGrid ) {
				// Normal intGrid
				for(cy in 0...li.cHei)
				for(cx in 0...li.cWid) {
					if( !li.hasIntGrid(cx,cy) )
						continue;

					g.beginFill( li.getIntGridColorAt(cx,cy), 1 );
					g.drawRect(cx*li.def.gridSize, cy*li.def.gridSize, li.def.gridSize, li.def.gridSize);
				}
			}

		case Entities:
			for(ei in li.entityInstances) {
				var e = createEntityRender(ei, li);
				e.setPosition(ei.x, ei.y);
				wrapper.addChild(e);
			}

		case Tiles:
			var td = editor.project.defs.getTilesetDef(li.def.tilesetDefUid);
			if( td!=null && td.isAtlasLoaded() ) {
				var tg = new h2d.TileGroup( td.getAtlasTile(), wrapper );

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
				var tg = new h2d.TileGroup( tileError, wrapper );
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

		applyLayerVisibility(li);
	}



	static function createFieldValuesRender(ei:data.inst.EntityInstance, fi:data.inst.FieldInstance) {
		var font = Assets.fontPixel;

		var valuesFlow = new h2d.Flow();
		valuesFlow.layout = Horizontal;
		valuesFlow.verticalAlign = Middle;

		// Array opening
		if( fi.def.isArray && fi.getArrayLength()>1 ) {
			var tf = new h2d.Text(font, valuesFlow);
			tf.textColor = ei.getSmartColor(true);
			tf.text = "[";
			tf.scale(FIELD_TEXT_SCALE);
		}

		for( idx in 0...fi.getArrayLength() ) {
			if( !fi.valueIsNull(idx) && !( !fi.def.editorAlwaysShow && fi.def.type==F_Bool && fi.isUsingDefault(idx) ) ) {
				if( fi.hasIconForDisplay(idx) ) {
					// Icon
					var w = new h2d.Flow(valuesFlow);
					var tile = fi.getIconForDisplay(idx);
					var bmp = new h2d.Bitmap( tile, w );
					var s = M.fmin( ei.def.width/ tile.width, ei.def.height/tile.height );
					bmp.setScale(s);
				}
				else if( fi.def.type==F_Color ) {
					// Color disc
					var g = new h2d.Graphics(valuesFlow);
					var r = 6;
					g.beginFill( fi.getColorAsInt(idx) );
					g.lineStyle(1, 0x0, 0.8);
					g.drawCircle(r,r,r, 16);
				}
				else {
					// Text render
					var tf = new h2d.Text(font, valuesFlow);
					tf.textColor = ei.getSmartColor(true);
					tf.filter = new dn.heaps.filter.PixelOutline();
					tf.maxWidth = 300;
					tf.scale(FIELD_TEXT_SCALE);
					var v = fi.getForDisplay(idx);
					if( fi.def.type==F_Bool && fi.def.editorDisplayMode==ValueOnly )
						tf.text = '${fi.getBool(idx)?"+":"-"}${fi.def.identifier}';
					else
						tf.text = v;
				}
			}

			// Array separator
			if( fi.def.isArray && idx<fi.getArrayLength()-1 ) {
				var tf = new h2d.Text(font, valuesFlow);
				tf.textColor = ei.getSmartColor(true);
				tf.text = ",";
				tf.scale(FIELD_TEXT_SCALE);
			}
		}

		// Array closing
		if( fi.def.isArray && fi.getArrayLength()>1 ) {
			var tf = new h2d.Text(font, valuesFlow);
			tf.textColor = ei.getSmartColor(true);
			tf.text = "]";
			tf.scale(FIELD_TEXT_SCALE);
		}

		return valuesFlow;
	}

	static inline function dashedLine(g:h2d.Graphics, fx:Float, fy:Float, tx:Float, ty:Float, dashLen=4.) {
		var a = Math.atan2(ty-fy, tx-fx);
		var len = M.dist(fx,fy, tx,ty);
		var cur = 0.;
		var count = M.ceil( len/(dashLen*2) );
		var dashLen = len / ( count%2==0 ? count+1 : count );

		while( cur<len ) {
			g.moveTo( fx+Math.cos(a)*cur, fy+Math.sin(a)*cur );
			g.lineTo( fx+Math.cos(a)*(cur+dashLen), fy+Math.sin(a)*(cur+dashLen) );
			cur+=dashLen*2;
		}
	}

	public static function createEntityRender(?ei:data.inst.EntityInstance, ?def:data.def.EntityDef, ?li:data.inst.LayerInstance, ?parent:h2d.Object) {
		if( def==null && ei==null )
			throw "Need at least 1 parameter";

		if( def==null )
			def = ei.def;

		// Init
		var wrapper = new h2d.Object(parent);

		var g = new h2d.Graphics(wrapper);
		g.x = Std.int( -def.width*def.pivotX );
		g.y = Std.int( -def.height*def.pivotY );

		// Render a tile
		function renderTile(tilesetId:Null<Int>, tileId:Null<Int>, mode:data.DataTypes.EntityTileRenderMode) {
			if( tileId==null || tilesetId==null ) {
				// Missing tile
				var p = 2;
				g.lineStyle(3, 0xff0000);
				g.moveTo(p,p);
				g.lineTo(def.width-p, def.height-p);
				g.moveTo(def.width-p, p);
				g.lineTo(p, def.height-p);
			}
			else {
				g.beginFill(def.color, 0.2);
				g.drawRect(0, 0, def.width, def.height);

				var td = Editor.ME.project.defs.getTilesetDef(tilesetId);
				var t = td.getTile(tileId);
				var bmp = new h2d.Bitmap(t, wrapper);
				switch mode {
					case Stretch:
						bmp.scaleX = def.width / bmp.tile.width;
						bmp.scaleY = def.height / bmp.tile.height;

					case Crop:
						if( bmp.tile.width>def.width || bmp.tile.height>def.height )
							bmp.tile = bmp.tile.sub(
								0, 0,
								M.fmin( bmp.tile.width, def.width ),
								M.fmin( bmp.tile.height, def.height )
							);
				}
				bmp.tile.setCenterRatio(def.pivotX, def.pivotY);
			}
		}

		// Base render
		var custTile = ei==null ? null : ei.getSmartTile();
		if( custTile!=null )
			renderTile(custTile.tilesetUid, custTile.tileId, Stretch);
		else
			switch def.renderMode {
			case Rectangle, Ellipse:
				g.beginFill(def.color);
				g.lineStyle(1, 0x0, 0.4);
				switch def.renderMode {
					case Rectangle:
						g.drawRect(0, 0, def.width, def.height);

					case Ellipse:
						g.drawEllipse(def.width*0.5, def.height*0.5, def.width*0.5, def.height*0.5, 0, def.width<=16 || def.height<=16 ? 16 : 0);

					case _:
				}
				g.endFill();

			case Cross:
				g.lineStyle(5, def.color, 1);
				g.moveTo(0,0);
				g.lineTo(def.width, def.height);
				g.moveTo(0,def.height);
				g.lineTo(def.width, 0);

			case Tile:
				renderTile(def.tilesetId, def.tileId, def.tileRenderMode);
			}

		// Pivot
		g.beginFill(def.color);
		g.lineStyle(1, 0x0, 0.5);
		var pivotSize = 3;
		g.drawRect(
			Std.int((def.width-pivotSize)*def.pivotX),
			Std.int((def.height-pivotSize)*def.pivotY),
			pivotSize, pivotSize
		);


		function _addBg(f:h2d.Flow, dark:Float) {
			var bg = new h2d.ScaleGrid(Assets.elements.getTile("fieldBg"), 2,2);
			f.addChildAt(bg, 0);
			f.getProperties(bg).isAbsolute = true;
			bg.color.setColor( C.addAlphaF( C.toBlack( ei.getSmartColor(false), dark ) ) );
			bg.alpha = 0.8;
			bg.x = -2;
			bg.y = 1;
			bg.width = f.outerWidth + M.fabs(bg.x)*2;
			bg.height = f.outerHeight;
		}

		// Display fields not marked as "Hidden"
		if( ei!=null && li!=null ) {
			// Init field wrappers
			var font = Assets.fontPixel;

			var custom = new h2d.Graphics(wrapper);

			var above = new h2d.Flow(wrapper);
			above.layout = Vertical;
			above.horizontalAlign = Middle;
			above.verticalSpacing = 1;

			var center = new h2d.Flow(wrapper);
			center.layout = Vertical;
			center.horizontalAlign = Middle;
			center.verticalSpacing = 1;

			var beneath = new h2d.Flow(wrapper);
			beneath.layout = Vertical;
			beneath.horizontalAlign = Middle;
			beneath.verticalSpacing = 1;

			// Attach fields
			for(fd in ei.def.fieldDefs) {
				var fi = ei.getFieldInstance(fd);

				// Value error
				var err = fi.getFirstErrorInValues();
				if( err!=null ) {
					var tf = new h2d.Text(font, above);
					tf.textColor = 0xffcc00;
					tf.text = '<$err?>';
				}

				// Skip hiddens
				if( fd.editorDisplayMode==Hidden )
					continue;

				if( !fi.def.editorAlwaysShow && ( fi.def.isArray && fi.getArrayLength()==0 || !fi.def.isArray && fi.isUsingDefault(0) ) )
					continue;

				// Position
				var fieldWrapper = new h2d.Flow();
				switch fd.editorDisplayPos {
					case Above: above.addChild(fieldWrapper);
					case Center: center.addChild(fieldWrapper);
					case Beneath: beneath.addChild(fieldWrapper);
				}

				switch fd.editorDisplayMode {
					case Hidden: // N/A

					case NameAndValue:
						var f = new h2d.Flow(fieldWrapper);
						f.verticalAlign = Middle;

						var tf = new h2d.Text(font, f);
						tf.textColor = ei.getSmartColor(true);
						tf.text = fd.identifier+" = ";
						tf.scale(FIELD_TEXT_SCALE);
						tf.filter = new dn.heaps.filter.PixelOutline();

						f.addChild( createFieldValuesRender(ei,fi) );

					case ValueOnly:
						fieldWrapper.addChild( createFieldValuesRender(ei,fi) );

					case RadiusPx:
						custom.lineStyle(1, ei.getSmartColor(false), 0.33);
						custom.drawCircle(0,0, fi.def.type==F_Float ? fi.getFloat(0) : fi.getInt(0));

					case RadiusGrid:
						custom.lineStyle(1, ei.getSmartColor(false), 0.33);
						custom.drawCircle(0,0, ( fi.def.type==F_Float ? fi.getFloat(0) : fi.getInt(0) ) * li.def.gridSize);

					case EntityTile:

					case PointStar, PointPath:
						var fx = ei.getCellCenterX(li.def);
						var fy = ei.getCellCenterY(li.def);
						custom.lineStyle(1, ei.getSmartColor(false), 0.66);

						for(i in 0...fi.getArrayLength()) {
							var pt = fi.getPointGrid(i);
							if( pt==null )
								continue;

							var tx = M.round( (pt.cx+0.5)*li.def.gridSize-ei.x );
							var ty = M.round( (pt.cy+0.5)*li.def.gridSize-ei.y );
							dashedLine(custom, fx,fy, tx,ty, 3);
							custom.drawRect( tx-2, ty-2, 4, 4 );

							if( fd.editorDisplayMode==PointPath ) {
								fx = tx;
								fy = ty;
							}
						}
				}

				// Field bg
				var needBg = switch fd.type {
					case F_Int, F_Float:
						switch fd.editorDisplayMode {
							case RadiusPx, RadiusGrid: false;
							case _: true;
						};
					case F_String, F_Text, F_Bool: true;
					case F_Color, F_Point: false;
					case F_Enum(enumDefUid): fd.editorDisplayMode!=EntityTile;
				}

				if( needBg )
					_addBg(fieldWrapper, 0.15);

				fieldWrapper.visible = fieldWrapper.numChildren>0;

			}

			// Identifier label
			if( ei.def.showName ) {
				var f = new h2d.Flow(above);
				var tf = new h2d.Text(Assets.fontPixel, f);
				tf.textColor = ei.getSmartColor(true);
				tf.text = def.identifier.substr(0,16);
				tf.scale(0.5);
				tf.x = Std.int( def.width*0.5 - tf.textWidth*tf.scaleX*0.5 );
				tf.y = 0;
				tf.filter = new dn.heaps.filter.PixelOutline();
				_addBg(f, 0.5);
			}

			// Update wrappers pos
			above.x = Std.int( -def.width*def.pivotX - above.outerWidth*0.5 + def.width*0.5 );
			above.y = Std.int( -above.outerHeight - def.height*def.pivotY - 1 );

			center.x = Std.int( -def.width*def.pivotX - center.outerWidth*0.5 + def.width*0.5 );
			center.y = Std.int( -def.height*def.pivotY - center.outerHeight*0.5 + def.height*0.5);

			beneath.x = Std.int( -def.width*def.pivotX - beneath.outerWidth*0.5 + def.width*0.5 );
			beneath.y = Std.int( def.height*(1-def.pivotY) + 1 );
		}

		return wrapper;
	}

	function applyLayerVisibility(li:data.inst.LayerInstance) {
		var wrapper = layerRenders.get(li.layerDefUid);
		if( wrapper==null )
			return;

		wrapper.visible = isLayerVisible(li);
		wrapper.alpha = li.def.displayOpacity * ( !settings.singleLayerMode || li==editor.curLayerInstance ? 1 : 0.2 );
		wrapper.filter = !settings.singleLayerMode || li==editor.curLayerInstance ? null : new h2d.filter.Group([
			C.getColorizeFilterH2d(0x8c99c1, 0.9),
			new h2d.filter.Blur(2),
		]);
	}

	@:allow(page.Editor)
	function applyAllLayersVisibility() {
		for(ld in editor.project.defs.layers) {
			var li = editor.curLevel.getLayerInstance(ld);
			applyLayerVisibility(li);
		}
	}

	public inline function invalidateLayer(?li:data.inst.LayerInstance, ?layerDefUid:Int) {
		if( li==null )
			li = editor.curLevel.getLayerInstance(layerDefUid);
		layerInvalidations.set( li.layerDefUid, { left:0, right:li.cWid-1, top:0, bottom:li.cHei-1 } );

		if( li.def.type==IntGrid )
			for(l in editor.curLevel.layerInstances)
				if( l.def.type==AutoLayer && l.def.autoSourceLayerDefUid==li.def.uid )
					invalidateLayer(l);
	}

	public inline function invalidateLayerArea(li:data.inst.LayerInstance, left:Int, right:Int, top:Int, bottom:Int) {
		if( layerInvalidations.exists(li.layerDefUid) ) {
			var bounds = layerInvalidations.get(li.layerDefUid);
			bounds.left = M.imin(bounds.left, left);
			bounds.right = M.imax(bounds.right, right);
		}
		else
			layerInvalidations.set( li.layerDefUid, { left:left, right:right, top:top, bottom:bottom } );

		// Invalidate linked auto-layers
		if( li.def.type==IntGrid )
			for(other in editor.curLevel.layerInstances)
				if( other.def.type==AutoLayer && other.def.autoSourceLayerDefUid==li.layerDefUid )
					invalidateLayerArea(other, left, right, top, bottom);
	}

	// public inline function invalidateAllLayers() {
	// 	for(li in editor.curLevel.layerInstances)
	// 		invalidateLayer(li);
	// }

	public inline function invalidateBg() {
		bgInvalidated = true;
	}

	public inline function invalidateAll() {
		allInvalidated = true;
	}

	override function postUpdate() {
		super.postUpdate();

		// Animated scrolling
		if( targetLevelX!=null ) {
			focusLevelX += ( targetLevelX - focusLevelX ) * 0.1;
			focusLevelY += ( targetLevelY - focusLevelY ) * 0.1;
			if( M.dist(targetLevelX, targetLevelY, focusLevelX, focusLevelY)<=4 )
				cancelAutoScrolling();
		}

		// Animate world zoom
		worldZoom += ( ( editor.worldMode ? 1 : 0 ) - worldZoom ) * 0.1;
		if( worldZoom>0.05 && worldZoom<0.95 )
			editor.ge.emitAtTheEndOfFrame(ViewportChanged);

		// World
		worldBg.wrapper.alpha += ( ( editor.worldMode ? 0.3 : 0 ) - worldBg.wrapper.alpha ) * 0.1;
		worldBg.wrapper.visible = worldBg.wrapper.alpha>=0.02;

		// Fade-out temporary rects
		var i = 0;
		while( i<rectBleeps.length ) {
			var o = rectBleeps[i];
			o.alpha-=tmod*0.042;
			o.setScale( 1 + 0.2 * (1-o.alpha) );
			if( o.alpha<=0 ) {
				o.remove();
				rectBleeps.splice(i,1);
			}
			else
				i++;
		}


		// World levels invalidation (one per frame)
		for( uid in worldLevelsInvalidations.keys() ) {
			renderWorldLevel( editor.project.getLevel(uid) );
			updateWorld();
			break;
		}


		// Render invalidation system
		if( allInvalidated ) {
			// Full
			renderAll();
			App.LOG.warning("Full render requested");
		}
		else {
			// Bg
			if( bgInvalidated ) {
				renderBounds();
				renderGrid();
				App.LOG.render("Rendered bg");
			}

			// Layers
			for( li in editor.curLevel.layerInstances )
				if( layerInvalidations.exists(li.layerDefUid) ) {
					var b = layerInvalidations.get(li.layerDefUid);
					if( li.def.isAutoLayer() )
						li.applyAllAutoLayerRulesAt( b.left, b.top, b.right-b.left+1, b.bottom-b.top+1 );
					renderLayer(li);
				}
		}

		applyGridVisibility();
		layersWrapper.visible = !editor.worldMode;
	}

}
