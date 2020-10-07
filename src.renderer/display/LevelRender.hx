package display;

class LevelRender extends dn.Process {
	static var MAX_FOCUS_PADDING = 200;

	public var editor(get,never) : Editor; inline function get_editor() return Editor.ME;

	public var enhanceActiveLayer(default,null) = false;
	public var focusLevelX(default,set) : Float;
	public var focusLevelY(default,set) : Float;
	public var zoom(get,set) : Float;
	public var unclampedZoom : Float;

	/** <LayerDefUID, Bool> **/
	var autoLayerRendering : Map<Int,Bool> = new Map();

	/** <LayerDefUID, Bool> **/
	var layerVis : Map<Int,Bool> = new Map();

	var layersWrapper : h2d.Layers;
	/** <LayerDefUID, h2d.Object> **/
	var layerRenders : Map<Int,h2d.Object> = new Map();

	var bounds : h2d.Graphics;
	var boundsGlow : h2d.Graphics;
	var grid : h2d.Graphics;
	var rectBleeps : Array<h2d.Object> = [];

	// Invalidation system (ie. render calls)
	var allInvalidated = true;
	var bgInvalidated = false;
	var layerInvalidations : Map<Int, { left:Int, right:Int, top:Int, bottom:Int }> = new Map();


	public function new() {
		super(editor);

		editor.ge.addGlobalListener(onGlobalEvent);

		createRootInLayers(editor.root, Const.DP_MAIN);

		bounds = new h2d.Graphics();
		root.add(bounds, Const.DP_UI);

		boundsGlow = new h2d.Graphics();
		root.add(boundsGlow, Const.DP_UI);

		grid = new h2d.Graphics();
		root.add(grid, Const.DP_UI);

		layersWrapper = new h2d.Layers();
		root.add(layersWrapper, Const.DP_MAIN);

		focusLevelX = 0;
		focusLevelY = 0;
		zoom = 3;
	}

	public function setFocus(x,y) {
		focusLevelX = x;
		focusLevelY = y;
	}

	public function fit() {
		focusLevelX = editor.curLevel.pxWid*0.5;
		focusLevelY = editor.curLevel.pxHei*0.5;

		var old = zoom;
		var pad = 100 * js.Browser.window.devicePixelRatio;
		zoom = M.fmin(
			editor.canvasWid() / ( editor.curLevel.pxWid + pad ),
			editor.canvasHei() / ( editor.curLevel.pxHei + pad )
		);

		// Fit closer if repeated
		if( old==zoom ) {
			var pad = 16 * js.Browser.window.devicePixelRatio;
			zoom = M.fmin(
				editor.canvasWid() / ( editor.curLevel.pxWid + pad ),
				editor.canvasHei() / ( editor.curLevel.pxHei + pad )
			);
		}
	}

	inline function set_focusLevelX(v) {
		focusLevelX = editor.curLevelId==null
			? v
			: M.fclamp( v, -MAX_FOCUS_PADDING/zoom, editor.curLevel.pxWid+MAX_FOCUS_PADDING/zoom );
		editor.ge.emitAtTheEndOfFrame( ViewportChanged );
		return focusLevelX;
	}

	inline function set_focusLevelY(v) {
		focusLevelY = editor.curLevelId==null
			? v
			: M.fclamp( v, -MAX_FOCUS_PADDING/zoom, editor.curLevel.pxHei+MAX_FOCUS_PADDING/zoom );
		editor.ge.emitAtTheEndOfFrame( ViewportChanged );
		return focusLevelY;
	}

	inline function set_zoom(v) {
		unclampedZoom = M.fclamp(v, 0.2, 16);
		editor.ge.emitAtTheEndOfFrame(ViewportChanged);
		return unclampedZoom;
	}

	inline function get_zoom() {
		if( unclampedZoom<=js.Browser.window.devicePixelRatio )
			return unclampedZoom;
		else
			return M.round(unclampedZoom*2)/2; // reduces tile flickering (#71)
	}

	public inline function levelToUiX(x:Float) {
		return M.round( x*zoom + root.x );
	}

	public inline function levelToUiY(y:Float) {
		return M.round( y*zoom + root.y );
	}

	override function onDispose() {
		super.onDispose();
		editor.ge.removeListener(onGlobalEvent);
	}

	function onGlobalEvent(e:GlobalEvent) {
		switch e {
			case ViewportChanged:
				root.setScale(zoom);
				root.x = M.round( editor.canvasWid()*0.5 - focusLevelX * zoom );
				root.y = M.round( editor.canvasHei()*0.5 - focusLevelY * zoom );

			case ProjectSaved, BeforeProjectSaving:

			case ProjectSelected:
				renderAll();
				fit();

			case ProjectSettingsChanged:
				invalidateBg();

			case LevelRestoredFromHistory:
				invalidateAll();

			case LayerInstanceRestoredFromHistory(li):
				invalidateLayer(li);

			case LevelSelected:
				renderAll();
				fit();

			case LevelResized:
				invalidateAll();

			case LayerInstanceVisiblityChanged(li):
				applyLayerVisibility(li);

			case LayerInstanceAutoRenderingChanged(li):
				invalidateLayer(li);

			case LayerInstanceSelected:
				applyAllLayersVisibility();
				invalidateBg();

			case LevelSettingsChanged:
				invalidateBg();

			case LayerDefRemoved(uid):
				if( layerRenders.exists(uid) ) {
					layerRenders.get(uid).remove();
					layerRenders.remove(uid);
				}

			case LayerDefSorted:
				for( li in editor.curLevel.layerInstances ) {
					var depth = editor.project.defs.getLayerDepth(li.def);
					if( layerRenders.exists(li.layerDefUid) )
						layersWrapper.add( layerRenders.get(li.layerDefUid), depth );
				}

			case LayerDefChanged:
				invalidateAll();

			case LayerRuleChanged(r), LayerRuleAdded(r):
				var li = editor.curLevel.getLayerInstanceFromRule(r);
				li.applyAutoLayerRule(r);
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

			case LayerRuleGroupChanged:
				invalidateLayer( editor.curLayerInstance );

			case LayerRuleGroupSorted:
				invalidateLayer( editor.curLayerInstance );

			case LayerRuleGroupCollapseChanged:

			case LayerInstanceChanged:

			case TilesetSelectionSaved(td):

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

			case LevelAdded:
			case LevelRemoved:
			case LevelSorted:
			case LayerDefAdded:

			case EntityDefAdded:
			case EntityFieldSorted:

			case ToolOptionChanged:

			case EnumDefAdded:
			case EnumDefSorted:
		}
	}

	public inline function autoLayerRenderingEnabled(li:led.inst.LayerInstance) {
		if( li==null || !li.def.isAutoLayer() )
			return false;

		return ( !autoLayerRendering.exists(li.layerDefUid) || autoLayerRendering.get(li.layerDefUid)==true );
	}

	public function setAutoLayerRendering(li:led.inst.LayerInstance, v:Bool) {
		if( li==null || !li.def.isAutoLayer() )
			return;

		autoLayerRendering.set(li.layerDefUid, v);
		editor.ge.emit( LayerInstanceAutoRenderingChanged(li) );
	}

	public function toggleAutoLayerRendering(li:led.inst.LayerInstance) {
		if( li!=null && li.def.isAutoLayer() )
			setAutoLayerRendering( li, !autoLayerRenderingEnabled(li) );
	}

	public inline function isLayerVisible(l:led.inst.LayerInstance) {
		return l!=null && ( !layerVis.exists(l.layerDefUid) || layerVis.get(l.layerDefUid)==true );
	}

	public function toggleLayer(li:led.inst.LayerInstance) {
		layerVis.set(li.layerDefUid, !isLayerVisible(li));
		editor.ge.emit( LayerInstanceVisiblityChanged(li) );

		if( isLayerVisible(li) )
			invalidateLayer(li);
	}

	public function showLayer(li:led.inst.LayerInstance) {
		layerVis.set(li.layerDefUid, true);
		editor.ge.emit( LayerInstanceVisiblityChanged(li) );
	}

	public function hideLayer(li:led.inst.LayerInstance) {
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
			Std.int(x+w*0.5) + editor.curLayerInstance.pxOffsetX,
			Std.int(y+h*0.5) + editor.curLayerInstance.pxOffsetY
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

	public inline function isGridVisible() return grid.visible;

	public function toggleGrid() {
		grid.visible = !grid.visible;
	}

	function renderGrid() {
		bgInvalidated = false;

		grid.clear();

		if( editor.curLayerInstance==null )
			return;

		var col = C.getPerceivedLuminosityInt( editor.project.bgColor) >= 0.8 ? 0x0 : 0xffffff;

		var l = editor.curLayerInstance;
		grid.lineStyle(1, editor.getGridSnapping() ? col : 0xff0000, editor.getGridSnapping() ? 0.07 : 0.07);
		for( cx in 0...editor.curLayerInstance.cWid+1 ) {
			grid.moveTo(cx*l.def.gridSize, 0);
			grid.lineTo(cx*l.def.gridSize, l.cHei*l.def.gridSize);
		}
		for( cy in 0...editor.curLayerInstance.cHei+1 ) {
			grid.moveTo(0, cy*l.def.gridSize);
			grid.lineTo(l.cWid*l.def.gridSize, cy*l.def.gridSize);
		}

		grid.x = editor.curLayerInstance.pxOffsetX;
		grid.y = editor.curLayerInstance.pxOffsetY;
	}


	public function renderAll() {
		allInvalidated = false;

		renderBounds();
		renderGrid();

		for(ld in editor.project.defs.layers) {
			var li = editor.curLevel.getLayerInstance(ld);
			if( li.def.isAutoLayer() )
				li.applyAllAutoLayerRules();
			renderLayer(li);
		}
	}


	function renderLayer(li:led.inst.LayerInstance) {
		layerInvalidations.remove(li.layerDefUid);

		// Create wrapper
		if( layerRenders.exists(li.layerDefUid) )
			layerRenders.get(li.layerDefUid).remove();

		var wrapper = new h2d.Object();
		wrapper.x = li.pxOffsetX;
		wrapper.y = li.pxOffsetY;

		// Register it
		layerRenders.set(li.layerDefUid, wrapper);
		var depth = editor.project.defs.getLayerDepth(li.def);
		layersWrapper.add( wrapper, depth );

		// Render
		switch li.def.type {
		case IntGrid, AutoLayer:
			var g = new h2d.Graphics(wrapper);

			if( li.def.isAutoLayer() && li.def.autoTilesetDefUid!=null && autoLayerRenderingEnabled(li) ) {
				// Auto-layer tiles
				var td = editor.project.defs.getTilesetDef( li.def.autoTilesetDefUid );
				var tg = new h2d.TileGroup( td.getAtlasTile(), wrapper);

				var groupIdx = li.def.autoRuleGroups.length-1;
				var anyTile = false;
				while( groupIdx>=0 ) {
					var rg = li.def.autoRuleGroups[groupIdx];
					if( rg.active ) {
						var ruleIdx = rg.rules.length-1;
						while( ruleIdx>=0 ) {
							var r = rg.rules[ruleIdx];
							if( r.active ) {
								var ruleResults = li.autoTiles.get(r.uid);
								for(cy in 0...li.cHei)
								for(cx in 0...li.cWid) {
									var at = ruleResults.get( li.coordId(cx,cy) );
									if( at!=null ) {
										switch r.tileMode {
											case Single:
												tg.addTransform(
													( cx + ( dn.M.hasBit(at.flips,0)?1:0 ) + li.def.tilePivotX ) * li.def.gridSize,
													( cy + ( dn.M.hasBit(at.flips,1)?1:0 ) + li.def.tilePivotX ) * li.def.gridSize,
													dn.M.hasBit(at.flips,0)?-1:1, dn.M.hasBit(at.flips,1)?-1:1, 0,
													td.getTile(at.tileIds[0])
												);

											case Stamp:
												// Render stamp tiles
												var stampRenderInfos = li.getRuleStampRenderInfos(r, td, at.tileIds, at.flips);
												for(tid in at.tileIds) {
													var tcx = td.getTileCx(tid);
													var tcy = td.getTileCy(tid);
													tg.addTransform(
														( cx + ( dn.M.hasBit(at.flips,0)?1:0 ) + li.def.tilePivotX ) * li.def.gridSize + stampRenderInfos.get(tid).xOff,
														( cy + ( dn.M.hasBit(at.flips,1)?1:0 ) + li.def.tilePivotX ) * li.def.gridSize + stampRenderInfos.get(tid).yOff,
														dn.M.hasBit(at.flips,0)?-1:1, dn.M.hasBit(at.flips,1)?-1:1, 0,
														td.getTile(tid)
													);
												}
										}
										anyTile = true;
									}
								}
							}

							ruleIdx--;
						}
					}

					groupIdx--;
				}

				// if( li.def.type==IntGrid && !anyTile && li.hasIntGrid(cx,cy) ) {
				// 	// Default render when no tile applies
				// 	g.beginFill( li.getIntGridColorAt(cx,cy), 1 );
				// 	g.drawRect(cx*li.def.gridSize, cy*li.def.gridSize, li.def.gridSize, li.def.gridSize);
				// }
		}
			else if( li.def.type==IntGrid ) {
				// Normal intGrid
				for(cy in 0...li.cHei)
				for(cx in 0...li.cWid) {
					var id = li.getIntGrid(cx,cy);
					if( id<0 )
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
					if( li.getGridTile(cx,cy)==null )
						continue;

					var t = td.getTile( li.getGridTile(cx,cy) );
					t.setCenterRatio(li.def.tilePivotX, li.def.tilePivotY);
					tg.add(
						(cx + li.def.tilePivotX) * li.def.gridSize,
						(cy + li.def.tilePivotX) * li.def.gridSize,
						t
					);
				}
			}
			else {
				// Missing tileset
				var tileError = led.def.TilesetDef.makeErrorTile(li.def.gridSize);
				var tg = new h2d.TileGroup( tileError, wrapper );
				for(cy in 0...li.cHei)
				for(cx in 0...li.cWid)
					if( li.getGridTile(cx,cy)!=null )
						tg.add(
							(cx + li.def.tilePivotX) * li.def.gridSize,
							(cy + li.def.tilePivotX) * li.def.gridSize,
							tileError
						);
			}
		}

		applyLayerVisibility(li);
	}



	static function createFieldValuesRender(ei:led.inst.EntityInstance, fi:led.inst.FieldInstance) {
		var font = Assets.fontPixel;

		var valuesFlow = new h2d.Flow();
		valuesFlow.layout = Horizontal;
		valuesFlow.verticalAlign = Middle;

		if( fi.def.isArray ) {
			valuesFlow.backgroundTile = hxd.Res.img.darkBg.toTile();
			valuesFlow.borderWidth = 2;
			valuesFlow.borderHeight = 2;
			valuesFlow.padding = 1;
		}

		// Array opening
		if( fi.def.isArray && fi.getArrayLength()>1 ) {
			var tf = new h2d.Text(font, valuesFlow);
			tf.textColor = ei.getSmartColor(true);
			tf.text = "[";
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
					var r = 4;
					g.beginFill( fi.getColorAsInt(idx) );
					g.lineStyle(1, 0x0, 0.8);
					g.drawCircle(r,r,r, 16);
				}
				else {
					// Text render
					var tf = new h2d.Text(font, valuesFlow);
					tf.textColor = ei.getSmartColor(true);
					tf.filter = new dn.heaps.filter.PixelOutline();
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
			}
		}

		// Array closing
		if( fi.def.isArray && fi.getArrayLength()>1 ) {
			var tf = new h2d.Text(font, valuesFlow);
			tf.textColor = ei.getSmartColor(true);
			tf.text = "]";
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

	public static function createEntityRender(?ei:led.inst.EntityInstance, ?def:led.def.EntityDef, ?li:led.inst.LayerInstance, ?parent:h2d.Object) {
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
		function renderTile(tilesetId:Null<Int>, tileId:Null<Int>, mode:led.LedTypes.EntityTileRenderMode) {
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
		var custTile = ei==null ? null : ei.getTileOverrideFromFields();
		if( custTile!=null )
			renderTile(custTile.tilesetUid, custTile.tileId, Stretch); // HACK specify other mode?
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


		// Display fields not marked as "Hidden"
		if( ei!=null && li!=null ) {
			// Init field wrappers
			var font = Assets.fontPixel;

			var custom = new h2d.Graphics(wrapper);

			var above = new h2d.Flow(wrapper);
			above.layout = Vertical;
			above.horizontalAlign = Middle;

			var center = new h2d.Flow(wrapper);
			center.layout = Vertical;
			center.horizontalAlign = Middle;

			var beneath = new h2d.Flow(wrapper);
			beneath.layout = Vertical;
			beneath.horizontalAlign = Middle;

			// Attach fields
			for(fd in ei.def.fieldDefs) {
				var fi = ei.getFieldInstance(fd);

				// Null enum warning
				if( fi.hasAnyErrorInValues() ) {
					var tf = new h2d.Text(font, above);
					tf.textColor = 0xffcc00;
					tf.text = "<ERROR>";
					// continue;
				}

				if( fd.editorDisplayMode==Hidden )
					continue;

				if( !fi.def.editorAlwaysShow && ( fi.def.isArray && fi.getArrayLength()==0 || !fi.def.isArray && fi.isUsingDefault(0) ) )
					continue;

				// Position
				var fieldWrapper = new h2d.Object();
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
						tf.filter = new dn.heaps.filter.PixelOutline();

						f.addChild( createFieldValuesRender(ei,fi) );

					case RadiusPx:
						custom.lineStyle(1, ei.getSmartColor(false), 0.33);
						custom.drawCircle(0,0, fi.def.type==F_Float ? fi.getFloat(0) : fi.getInt(0));

					case RadiusGrid:
						custom.lineStyle(1, ei.getSmartColor(false), 0.33);
						custom.drawCircle(0,0, ( fi.def.type==F_Float ? fi.getFloat(0) : fi.getInt(0) ) * li.def.gridSize);

					case ValueOnly:
						fieldWrapper.addChild( createFieldValuesRender(ei,fi) );

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

			}

			// Update wrappers pos
			above.x = Std.int( -def.width*def.pivotX - above.outerWidth*0.5 + def.width*0.5 );
			above.y = Std.int( -above.outerHeight - def.height*def.pivotY );

			center.x = Std.int( -def.width*def.pivotX - center.outerWidth*0.5 + def.width*0.5 );
			center.y = Std.int( -def.height*def.pivotY - center.outerHeight*0.5 + def.height*0.5);

			beneath.x = Std.int( -def.width*def.pivotX - beneath.outerWidth*0.5 + def.width*0.5 );
			beneath.y = Std.int( def.height*(1-def.pivotY) );
		}

		return wrapper;
	}

	public function setEnhanceActiveLayer(v:Bool) {
		enhanceActiveLayer = v;
		editor.jMainPanel.find("input#enhanceActiveLayer").prop("checked", v);
		applyAllLayersVisibility();
		editor.selectionTool.clear();
	}

	function applyLayerVisibility(li:led.inst.LayerInstance) {
		var wrapper = layerRenders.get(li.layerDefUid);
		if( wrapper==null )
			return;

		wrapper.visible = isLayerVisible(li);
		wrapper.alpha = li.def.displayOpacity * ( !enhanceActiveLayer || li==editor.curLayerInstance ? 1 : 0.4 );
		wrapper.filter = !enhanceActiveLayer || li==editor.curLayerInstance ? null : new h2d.filter.Blur(4);
	}

	function applyAllLayersVisibility() {
		for(ld in editor.project.defs.layers) {
			var li = editor.curLevel.getLayerInstance(ld);
			applyLayerVisibility(li);
		}
	}


	public inline function invalidateLayer(?li:led.inst.LayerInstance, ?layerDefUid:Int) {
		if( li==null )
			li = editor.curLevel.getLayerInstance(layerDefUid);
		layerInvalidations.set( li.layerDefUid, { left:0, right:li.cWid-1, top:0, bottom:li.cHei-1 } );
	}

	public inline function invalidateLayerArea(li:led.inst.LayerInstance, left:Int, right:Int, top:Int, bottom:Int) {
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

		// Fade-out temporary rects
		var i = 0;
		while( i<rectBleeps.length ) {
			var o = rectBleeps[i];
			o.alpha-=tmod*0.05;
			o.setScale( 1 + 0.2 * (1-o.alpha) );
			if( o.alpha<=0 ) {
				o.remove();
				rectBleeps.splice(i,1);
			}
			else
				i++;
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
	}

}
