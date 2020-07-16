package display;

class LevelRender extends dn.Process {
	static var MAX_FOCUS_PADDING = 200;
	static var _entityRenderCache : Map<Int, h3d.mat.Texture> = new Map();

	public var client(get,never) : Client; inline function get_client() return Client.ME;

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

	public function new() {
		super(client);

		client.ge.addGlobalListener(onGlobalEvent);

		createRootInLayers(client.root, Const.DP_MAIN);

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
		focusLevelX = client.curLevel.pxWid*0.5;
		focusLevelY = client.curLevel.pxHei*0.5;
		zoom = 1;
	}

	inline function set_focusLevelX(v) {
		focusLevelX = client.curLevel==null
			? v
			: M.fclamp( v, -MAX_FOCUS_PADDING/zoom, client.curLevel.pxWid+MAX_FOCUS_PADDING/zoom );
		client.ge.emitAtTheEndOfFrame( ViewportChanged );
		return focusLevelX;
	}

	inline function set_focusLevelY(v) {
		focusLevelY = client.curLevel==null
			? v
			: M.fclamp( v, -MAX_FOCUS_PADDING/zoom, client.curLevel.pxHei+MAX_FOCUS_PADDING/zoom );
		client.ge.emitAtTheEndOfFrame( ViewportChanged );
		return focusLevelY;
	}

	inline function set_zoom(v) {
		zoom = M.fclamp(v, 0.2, 16);
		client.ge.emitAtTheEndOfFrame(ViewportChanged);
		return zoom;
	}

	override function onDispose() {
		super.onDispose();
		client.ge.removeListener(onGlobalEvent);
	}

	function onGlobalEvent(e:GlobalEvent) {
		switch e {
			case ViewportChanged:
				root.setScale(zoom);
				root.x = w()*0.5 - focusLevelX * zoom;
				root.y = h()*0.5 - focusLevelY * zoom;

			case ProjectSelected:
				invalidateCaches();
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

			case TilesetDefChanged:
				invalidate();

			case EntityDefRemoved, EntityDefChanged, EntityDefSorted:
				invalidate();

			case EntityFieldAdded, EntityFieldRemoved, EntityFieldDefChanged, EntityFieldInstanceChanged:
				invalidate();

			case EnumDefRemoved, EnumDefChanged:
				invalidate();

			case LevelAdded:
			case LevelSorted:
			case LayerDefAdded:
			case EntityDefAdded:
			case EntityFieldSorted:
			case ToolOptionChanged:
			case EnumDefAdded:
		}
	}

	public inline function isLayerVisible(l:led.inst.LayerInstance) {
		return l!=null && ( !layerVis.exists(l.layerDefId) || layerVis.get(l.layerDefId)==true );
	}

	public function toggleLayer(l:led.inst.LayerInstance) {
		layerVis.set(l.layerDefId, !isLayerVisible(l));
		client.ge.emit(LayerInstanceVisiblityChanged);
		if( isLayerVisible(l) )
			invalidate();
	}

	public function showLayer(l:led.inst.LayerInstance) {
		layerVis.set(l.layerDefId, true);
		client.ge.emit(LayerInstanceVisiblityChanged);
	}

	public function hideLayer(l:led.inst.LayerInstance) {
		layerVis.set(l.layerDefId, false);
		client.ge.emit(LayerInstanceVisiblityChanged);
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
		bounds.drawRect(0, 0, client.curLevel.pxWid, client.curLevel.pxHei);

		glow.clear();
		glow.beginFill(0xff00ff);
		glow.drawRect(0, 0, client.curLevel.pxWid, client.curLevel.pxHei);
		var shadow = new h2d.filter.Glow( 0x0, 0.6, 128, true );
		shadow.knockout = true;
		glow.filter = shadow;

		// Grid
		var col = C.getPerceivedLuminosityInt( client.project.bgColor) >= 0.8 ? 0x0 : 0xffffff;

		grid.clear();
		if( client.curLayerInstance==null )
			return;

		var l = client.curLayerInstance;
		grid.lineStyle(1, col, 0.2);
		for( cx in 0...client.curLayerInstance.cWid+1 ) {
			grid.moveTo(cx*l.def.gridSize, 0);
			grid.lineTo(cx*l.def.gridSize, l.cHei*l.def.gridSize);
		}
		for( cy in 0...client.curLayerInstance.cHei+1 ) {
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

		for(ld in client.project.defs.layers) {
			var li = client.curLevel.getLayerInstance(ld);
			var wrapper = new h2d.Object();
			root.add(wrapper,Const.DP_MAIN);
			root.under(wrapper);
			layerWrappers.set(li.layerDefId, wrapper);
			wrapper.x = li.pxOffsetX;
			wrapper.y = li.pxOffsetY;

			if( !isLayerVisible(li) )
				continue;

			var grid = li.def.gridSize;
			switch li.def.type {
				case IntGrid, Tiles:
					li.render(wrapper);

				case Entities:
					for(ei in li.entityInstances) {
						var o = createEntityRender(ei, wrapper);
						o.setPosition(ei.x, ei.y);
					}
			}
		}

		updateLayersVisibility();
	}


	public static function invalidateCaches() {
		for(tex in _entityRenderCache)
			tex.dispose();
		_entityRenderCache = new Map();
	}


	public static function createEntityRender(?ei:led.inst.EntityInstance, ?def:led.def.EntityDef, ?parent:h2d.Object) {
		if( def==null && ei==null )
			throw "Need at least 1 parameter";

		if( def==null )
			def = ei.def;

		if( !_entityRenderCache.exists(def.uid) ) {
			var g = new h2d.Graphics();
			g.beginFill(def.color);
			g.lineStyle(1, 0x0, 0.25);
			g.drawRect(0, 0, def.width, def.height);

			g.lineStyle(1, 0x0, 0.5);
			var pivotSize = 3;
			g.drawRect(
				Std.int((def.width-pivotSize)*def.pivotX),
				Std.int((def.height-pivotSize)*def.pivotY),
				pivotSize, pivotSize
			);

			var tex = new h3d.mat.Texture(def.width, def.height, [Target]);
			g.drawTo(tex);
			_entityRenderCache.set(def.uid, tex);
		}

		var wrapper = new h2d.Object(parent);

		// Entity base render
		var bmp = new h2d.Bitmap(wrapper);
		bmp.tile = h2d.Tile.fromTexture( _entityRenderCache.get(def.uid) );
		bmp.tile.setCenterRatio(def.pivotX, def.pivotY);

		// Display fields not marked as "Hidden"
		if( ei!=null ) {
			// Init field wrappers
			var font = Assets.fontPixel;
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

				if( fd.type.getIndex()==led.LedTypes.FieldType.F_Enum(null).getIndex() && fi.getEnumValue()==null && !fd.canBeNull ) {
					// Null enum warning
					var tf = new h2d.Text(font, above);
					tf.textColor = 0xffcc00;
					tf.text = "!ERR!";
					continue;
				}

				if( fd.editorDisplayMode==Hidden )
					continue;

				if( fi.isUsingDefault() )
					continue;

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
						tf.textColor = C.toWhite(ei.def.color, 0.6);
						var v = fi.getForDisplay();
						tf.text = fd.name+" = "+v;

					case ValueOnly:
						if( !fi.valueIsNull() && !( fd.type==F_Bool && fi.getBool()==false ) ) {
							if( fd.type==F_Color ) {
								var g = new h2d.Graphics(fieldWrapper);
								var r = 4;
								g.beginFill(fi.getColorAsInt());
								g.lineStyle(1, 0x0, 0.8);
								g.drawCircle(r,r,r, 16);
							}
							else {
								var tf = new h2d.Text(font, fieldWrapper);
								tf.textColor = C.toWhite(ei.def.color, 0.6);
								var v = fi.getForDisplay();
								if( fd.type==F_Bool )
									tf.text = '[${fd.name}]';
								else
									tf.text = v;
							}
						}
				}
			}

			// Update wrappers pos
			above.x = Std.int( -bmp.tile.width*def.pivotX - above.outerWidth*0.5 + bmp.tile.width*0.5 );
			above.y = Std.int( -above.outerHeight - bmp.tile.height*def.pivotY );

			center.x = Std.int( -bmp.tile.width*def.pivotX - center.outerWidth*0.5 + bmp.tile.width*0.5 );
			center.y = Std.int( -bmp.tile.height*def.pivotY - center.outerHeight*0.5 + bmp.tile.height*0.5);

			beneath.x = Std.int( -bmp.tile.width*def.pivotX - beneath.outerWidth*0.5 + bmp.tile.width*0.5 );
			beneath.y = Std.int( bmp.tile.height*(1-def.pivotY) );
		}

		return wrapper;
	}

	function updateLayersVisibility() {
		for(ld in client.project.defs.layers) {
			var li = client.curLevel.getLayerInstance(ld);
			var wrapper = layerWrappers.get(ld.uid);
			if( wrapper==null )
				continue;

			wrapper.visible = isLayerVisible(li);
			wrapper.alpha = li.def.displayOpacity;
			// wrapper.alpha = li.def.displayOpacity * ( li==client.curLayerInstance ? 1 : 0.25 );
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
