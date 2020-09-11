package display;

class LevelRender extends dn.Process {
	static var MAX_FOCUS_PADDING = 200;

	public var editor(get,never) : Editor; inline function get_editor() return Editor.ME;

	public var enhanceActiveLayer(default,null) = true;
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

		var pad = 100 * js.Browser.window.devicePixelRatio;
		zoom = M.fmin(
			editor.canvasWid() / ( editor.curLevel.pxWid + pad ),
			editor.canvasHei() / ( editor.curLevel.pxHei + pad )
		);
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
				invalidateAllLayers();

			case LayerDefChanged:
				invalidateAll();

			case LayerRuleChanged(r), LayerRuleAdded(r):
				var li = editor.curLevel.getLayerInstanceFromRule(r);
				li.applyAutoLayerRule(r);
				invalidateLayer(li);

			case LayerRuleSorted:
				invalidateLayer( editor.curLayerInstance );

			case LayerRuleRemoved(r):
				var li = editor.curLevel.getLayerInstanceFromRule(r);
				invalidateLayer( li==null ? editor.curLayerInstance : li );

			case LayerInstanceChanged:

			case TilesetSelectionSaved(td):

			case TilesetDefChanged(td), TilesetDefRemoved(td):
				for(li in editor.curLevel.layerInstances)
					if( li.def.isUsingTileset(td) )
						invalidateLayer(li);

			case TilesetDefAdded(td):

			case EntityDefRemoved, EntityDefChanged, EntityDefSorted:
				for(li in editor.curLevel.layerInstances)
					if( li.def.type==Entities )
						invalidateLayer(li);

			case EntityFieldAdded(ed), EntityFieldRemoved(ed), EntityFieldDefChanged(ed):
				var li = editor.curLevel.getLayerInstanceFromEntity(ed);
				invalidateLayer( li==null ? editor.curLayerInstance : li );

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
		if( li==null || li.def.type!=IntGrid )
			return false;

		return ( !autoLayerRendering.exists(li.layerDefUid) || autoLayerRendering.get(li.layerDefUid)==true );
	}

	public function setAutoLayerRendering(li:led.inst.LayerInstance, v:Bool) {
		if( li==null || li.def.type!=IntGrid )
			return;

		autoLayerRendering.set(li.layerDefUid, v);
		editor.ge.emit(LayerDefChanged); // HACK not the right event
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
		g.setPosition( Std.int(x+w*0.5), Std.int(y+h*0.5) );
		root.add(g, Const.DP_UI);
	}

	public inline function bleepRectCase(cx:Int, cy:Int, cWid:Int, cHei:Int, col:UInt, thickness=1) {
		var li = editor.curLayerInstance;
		bleepRectPx(
			cx*li.def.gridSize,
			cy*li.def.gridSize,
			cWid*li.def.gridSize,
			cHei*li.def.gridSize,
			0xff00ff, 2
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
		case IntGrid:
			var g = new h2d.Graphics(wrapper);

			if( li.def.isAutoLayer() && autoLayerRenderingEnabled(li) ) {
				// Auto-layer tiles
				var td = editor.project.defs.getTilesetDef( li.def.autoTilesetDefUid );
				var tg = new h2d.TileGroup( td.getAtlasTile(), wrapper);

				for(cy in 0...li.cHei)
				for(cx in 0...li.cWid) {
					var i = li.def.rules.length-1;
					while( i>=0 ) {
						var r = li.def.rules[i];
						var at = li.autoTiles.get(r.uid).get( li.coordId(cx,cy) );
						if( at!=null ) {
							tg.addTransform(
								( cx + ( dn.M.hasBit(at.flips,0)?1:0 ) + li.def.tilePivotX ) * li.def.gridSize,
								( cy + ( dn.M.hasBit(at.flips,1)?1:0 ) + li.def.tilePivotX ) * li.def.gridSize,
								dn.M.hasBit(at.flips,0)?-1:1, dn.M.hasBit(at.flips,1)?-1:1, 0,
								td.getTile( r.tileIds[ dn.M.randSeedCoords( r.seed, cx,cy, r.tileIds.length ) ] )
							);
						}

						i--;
					}
				}
			}
			else {
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
			// not meant to be rendered
			for(ei in li.entityInstances) {
				var e = createEntityRender(ei);
				e.setPosition(ei.x, ei.y);
				wrapper.addChild(e);
			}

		case Tiles:
			var td = editor.project.defs.getTilesetDef(li.def.tilesetDefUid);
			var tg = new h2d.TileGroup( td.getAtlasTile(), wrapper );

			for(cy in 0...li.cHei)
			for(cx in 0...li.cWid) {
				if( li.getGridTile(cx,cy)==null )
					continue;

				var t = td!=null ? td.getTile( li.getGridTile(cx,cy) ) : led.def.TilesetDef.makeErrorTile(li.def.gridSize);
				t.setCenterRatio(li.def.tilePivotX, li.def.tilePivotY);
				tg.add(
					(cx + li.def.tilePivotX) * li.def.gridSize,
					(cy + li.def.tilePivotX) * li.def.gridSize,
					t
				);
			}
		}

		applyLayerVisibility(li);
	}


	static function getFieldColor(ei:led.inst.EntityInstance, fd:led.def.FieldDef) {
		for(fd in ei.def.fieldDefs)
			if( fd.type==F_Color )
				return ei.getColorField(fd.identifier);
		return C.toWhite(ei.def.color, 0.5);
	}

	public static function createEntityRender(?ei:led.inst.EntityInstance, ?def:led.def.EntityDef, ?parent:h2d.Object) {
		if( def==null && ei==null )
			throw "Need at least 1 parameter";

		if( def==null )
			def = ei.def;

		var wrapper = new h2d.Object(parent);

		// Base render
		var g = new h2d.Graphics(wrapper);
		g.x = Std.int( -def.width*def.pivotX );
		g.y = Std.int( -def.height*def.pivotY );

		switch def.renderMode {
			case Rectangle, Ellipse:
				g.beginFill(def.color);
				g.lineStyle(1, 0x0, 0.25);
				switch def.renderMode {
					case Rectangle:
						g.drawRect(0, 0, def.width, def.height);

					case Ellipse:
						g.drawEllipse(def.width*0.5, def.height*0.5, def.width*0.5, def.height*0.5);

					case _:
				}
				g.endFill();

			case Tile:
				if( def.tileId==null || def.tilesetId==null ) {
					// Missing tile
					var p = 2;
					g.lineStyle(3, 0xff0000);
					g.moveTo(p,p);
					g.lineTo(def.width-p, def.height-p);
					g.moveTo(def.width-p, p);
					g.lineTo(p, def.height-p);
				}
				else {
					g.lineStyle(1, def.color, 1);
					g.drawRect(0,0,def.width,def.height);

					var td = Editor.ME.project.defs.getTilesetDef(def.tilesetId);
					var t = td.getTile(def.tileId);
					t.setCenterRatio(def.pivotX, def.pivotY);
					var bmp = new h2d.Bitmap(t, wrapper);
				}
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
		if( ei!=null ) {
			// Init field wrappers
			var font = Assets.fontPixelOutline;
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
				if( fd.type.getIndex()==led.LedTypes.FieldType.F_Enum(null).getIndex() && fi.getEnumValue()==null && !fd.canBeNull ) {
					var tf = new h2d.Text(font, above);
					tf.textColor = 0xffcc00;
					tf.text = "!ERR!";
					continue;
				}

				if( fd.editorDisplayMode==Hidden )
					continue;

				if( fi.isUsingDefault() )
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
						var tf = new h2d.Text(font, fieldWrapper);
						tf.textColor = getFieldColor(ei,fd);
						var v = fi.getForDisplay();
						tf.text = fd.identifier+" = "+v;

					case ValueOnly:
						if( !fi.valueIsNull() && !( fd.type==F_Bool && fi.getBool()==false ) ) {
							if( fi.hasIconForDisplay() ) {
								var tile = fi.getIconForDisplay();
								var bmp = new h2d.Bitmap( tile, fieldWrapper );
								var s = M.fmin( ei.def.width/ tile.width, ei.def.height/tile.height );
								bmp.setScale(s);
							}
							else if( fd.type==F_Color ) {
								var g = new h2d.Graphics(fieldWrapper);
								var r = 4;
								g.beginFill(fi.getColorAsInt());
								g.lineStyle(1, 0x0, 0.8);
								g.drawCircle(r,r,r, 16);
							}
							else {
								var tf = new h2d.Text(font, fieldWrapper);
								tf.textColor = getFieldColor(ei,fd);
								var v = fi.getForDisplay();
								if( fd.type==F_Bool )
									tf.text = '[${fd.identifier}]';
								else
									tf.text = v;
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
	}

	public inline function invalidateAllLayers() {
		for(li in editor.curLevel.layerInstances)
			invalidateLayer(li);
	}

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
		}
		else {
			// Bg
			if( bgInvalidated ) {
				renderBounds();
				renderGrid();
			}

			// Layers
			for( li in editor.curLevel.layerInstances )
				if( layerInvalidations.exists(li.layerDefUid) ) {
					var b = layerInvalidations.get(li.layerDefUid);
					if( li.def.isAutoLayer() )
						li.applyAllAutoLayerRulesAt(b.left, b.top, b.right-b.left+1, b.bottom-b.top+1);
					renderLayer(li);
				}
		}
	}

}
