package display;

class LevelRender extends dn.Process {
	static var MAX_FOCUS_PADDING = 200;

	public var editor(get,never) : Editor; inline function get_editor() return Editor.ME;

	var layerAutoRender : Map<Int,Bool> = new Map();
	var layerVis : Map<Int,Bool> = new Map();
	var layerWrappers : Map<Int,h2d.Object> = new Map();
	var invalidated = true;

	var bounds : h2d.Graphics;
	var glow : h2d.Graphics;
	var grid : h2d.Graphics;
	var fadingRects : Array<h2d.Object> = [];

	public var focusLevelX(default,set) : Float;
	public var focusLevelY(default,set) : Float;
	public var zoom(default,set) : Float;

	public var enhanceActiveLayer(default,null) = true;

	public function new() {
		super(editor);

		editor.ge.addGlobalListener(onGlobalEvent);

		createRootInLayers(editor.root, Const.DP_MAIN);

		bounds = new h2d.Graphics();
		root.add(bounds, Const.DP_UI);

		glow = new h2d.Graphics();
		root.add(glow, Const.DP_UI);

		grid = new h2d.Graphics();
		root.add(grid, Const.DP_UI);

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
		zoom = M.fclamp(v, 0.2, 16);
		editor.ge.emitAtTheEndOfFrame(ViewportChanged);
		return zoom;
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
				root.x = editor.canvasWid()*0.5 - focusLevelX * zoom;
				root.y = editor.canvasHei()*0.5 - focusLevelY * zoom;

			case ProjectSelected:
				renderAll();
				fit();

			case ProjectSettingsChanged, LayerInstanceRestoredFromHistory, LevelRestoredFromHistory:
				invalidate();

			case LevelSelected:
				renderAll();
				fit();

			case LevelResized:
				invalidate();

			case LayerInstanceVisiblityChanged:
				updateLayersVisibility();

			case LayerInstanceSelected:
				updateLayersVisibility();
				renderBg();

			case LevelSettingsChanged:
				invalidate();

			case LayerDefRemoved, LayerDefChanged, LayerDefSorted:
				invalidate();

			case LayerInstanceChanged:
				invalidate(); // TODO optim needed to render only the changed layer

			case TilesetSelectionSaved:

			case TilesetDefChanged, TilesetDefRemoved:
				invalidate();

			case TilesetDefAdded:

			case EntityDefRemoved, EntityDefChanged, EntityDefSorted:
				invalidate();

			case EntityFieldAdded, EntityFieldRemoved, EntityFieldDefChanged, EntityFieldInstanceChanged:
				invalidate();

			case EnumDefRemoved, EnumDefChanged, EnumDefValueRemoved:
				invalidate();

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

	public inline function isLayerAutoRendered(li:led.inst.LayerInstance) {
		if( li==null || li.def.type!=IntGrid )
			return false;

		return ( !layerAutoRender.exists(li.layerDefUid) || layerAutoRender.get(li.layerDefUid)==true );
	}

	public function setLayerAutoRender(li:led.inst.LayerInstance, v:Bool) {
		if( li==null || li.def.type!=IntGrid )
			return;

		layerAutoRender.set(li.layerDefUid, v);
		editor.ge.emit(LayerDefChanged); // HACK not the right event
	}

	public function toggleLayerAutoRender(li:led.inst.LayerInstance) {
		if( li!=null && li.def.isAutoLayer() )
			setLayerAutoRender( li, !isLayerAutoRendered(li) );
	}

	public inline function isLayerVisible(l:led.inst.LayerInstance) {
		return l!=null && ( !layerVis.exists(l.layerDefUid) || layerVis.get(l.layerDefUid)==true );
	}

	public function toggleLayer(l:led.inst.LayerInstance) {
		layerVis.set(l.layerDefUid, !isLayerVisible(l));
		editor.ge.emit(LayerInstanceVisiblityChanged);
		if( isLayerVisible(l) )
			invalidate();
	}

	public function showLayer(l:led.inst.LayerInstance) {
		layerVis.set(l.layerDefUid, true);
		editor.ge.emit(LayerInstanceVisiblityChanged);
	}

	public function hideLayer(l:led.inst.LayerInstance) {
		layerVis.set(l.layerDefUid, false);
		editor.ge.emit(LayerInstanceVisiblityChanged);
	}

	public function showRect(x:Int, y:Int, w:Int, h:Int, col:UInt, thickness=1) {
		var pad = 5;
		var g = new h2d.Graphics();
		fadingRects.push(g);
		g.lineStyle(thickness, col);
		g.drawRect( Std.int(-pad-w*0.5), Std.int(-pad-h*0.5), w+pad*2, h+pad*2 );
		g.setPosition( Std.int(x+w*0.5), Std.int(y+h*0.5) );
		root.add(g, Const.DP_UI);
	}

	public inline function showHistoryBounds(layerId:Int, bounds:HistoryStateBounds, col:UInt) {
		showRect(bounds.x, bounds.y, bounds.wid, bounds.hei, col, 2);
	}

	public function renderBg() {
		// Bounds
		bounds.clear();
		bounds.lineStyle(1, 0xffffff, 0.7);
		bounds.drawRect(0, 0, editor.curLevel.pxWid, editor.curLevel.pxHei);

		glow.clear();
		glow.beginFill(0xff00ff);
		glow.drawRect(0, 0, editor.curLevel.pxWid, editor.curLevel.pxHei);
		var shadow = new h2d.filter.Glow( 0x0, 0.6, 128, true );
		shadow.knockout = true;
		glow.filter = shadow;

		// Grid
		var col = C.getPerceivedLuminosityInt( editor.project.bgColor) >= 0.8 ? 0x0 : 0xffffff;

		grid.clear();
		if( editor.curLayerInstance==null )
			return;

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
		invalidated = false;
		renderBg();
		renderLayers();
	}

	public function renderLayers() {
		for(e in layerWrappers)
			e.remove();
		layerWrappers = new Map();

		for(ld in editor.project.defs.layers) {
			var li = editor.curLevel.getLayerInstance(ld);
			var wrapper = new h2d.Object();
			root.add(wrapper,Const.DP_MAIN);
			root.under(wrapper);
			layerWrappers.set(li.layerDefUid, wrapper);
			wrapper.x = li.pxOffsetX;
			wrapper.y = li.pxOffsetY;

			if( !isLayerVisible(li) )
				continue;

			var grid = li.def.gridSize;
			switch li.def.type {
				case IntGrid, Tiles:
					li.render(wrapper, isLayerAutoRendered(li));

				case Entities:
					for(ei in li.entityInstances) {
						var o = createEntityRender(ei, wrapper);
						o.setPosition(ei.x, ei.y);
					}
			}
		}

		updateLayersVisibility();
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
		updateLayersVisibility();
	}

	function updateLayersVisibility() {
		for(ld in editor.project.defs.layers) {
			var li = editor.curLevel.getLayerInstance(ld);
			var wrapper = layerWrappers.get(ld.uid);
			if( wrapper==null )
				continue;

			wrapper.visible = isLayerVisible(li);
			wrapper.alpha = li.def.displayOpacity * ( !enhanceActiveLayer || li==editor.curLayerInstance ? 1 : 0.4 );
			wrapper.filter = !enhanceActiveLayer || li==editor.curLayerInstance ? null : new h2d.filter.Blur(4);
		}
	}


	public inline function invalidate() {
		invalidated = true;
	}

	override function postUpdate() {
		super.postUpdate();

		// Fade-out temporary rects
		var i = 0;
		while( i<fadingRects.length ) {
			var o = fadingRects[i];
			o.alpha-=tmod*0.05;
			o.setScale( 1 + 0.2 * (1-o.alpha) );
			if( o.alpha<=0 )
				fadingRects.splice(i,1);
			else
				i++;
		}

		// Re-render
		if( invalidated ) {
			invalidated = false;
			renderAll();
		}
	}

}
