package display;

class LevelRender extends dn.Process {
	static var MAX_FOCUS_PADDING = 200;
	static var _entityRenderCache : Map<Int, h3d.mat.Texture> = new Map();

	public var client(get,never) : Client; inline function get_client() return Client.ME;

	var layerVis : Map<Int,Bool> = new Map();
	var layerWrappers : Map<Int,h2d.Object> = new Map();
	var invalidated = true;

	var bg : h2d.Graphics;
	var grid : h2d.Graphics;
	var fadingRects : Array<h2d.Object> = [];

	public var focusLevelX(default,set) : Float = 0.;
	public var focusLevelY(default,set) : Float = 0.;
	public var zoom(default,set) : Float = 3.0;

	public function new() {
		super(client);

		client.ge.addGlobalListener(onGlobalEvent);

		createRootInLayers(client.root, Const.DP_MAIN);

		bg = new h2d.Graphics();
		root.add(bg, Const.DP_BG);
		bg.filter = new h2d.filter.DropShadow(0, 0, 0x0, 0.7, 64, true);

		grid = new h2d.Graphics();
		root.add(grid, Const.DP_UI);

		focusLevelX = 0;
		focusLevelY = 0;
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
		return focusLevelX = client.curLevel==null
			? v
			: M.fclamp( v, -MAX_FOCUS_PADDING/zoom, client.curLevel.pxWid+MAX_FOCUS_PADDING/zoom );
	}

	inline function set_focusLevelY(v) {
		return focusLevelY = client.curLevel==null
			? v
			: M.fclamp( v, -MAX_FOCUS_PADDING/zoom, client.curLevel.pxHei+MAX_FOCUS_PADDING/zoom );
	}

	function set_zoom(v) {
		return zoom = M.fclamp(v, 0.2, 16);
	}

	override function onDispose() {
		super.onDispose();
		client.ge.removeListener(onGlobalEvent);
	}

	function onGlobalEvent(e:GlobalEvent) {
		switch e {
			case ProjectSelected:
				invalidateCaches();
				renderAll();
				fit();

			case ProjectSettingsChanged, LayerInstanceRestoredFromHistory:
				invalidate();

			case LevelSelected:
				renderAll();
				fit();

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

			case LevelAdded:
			case LayerDefAdded:
			case EntityDefAdded:
			case EntityFieldSorted:
			case ToolOptionChanged:
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
		// Bg
		bg.clear();
		bg.beginFill(client.project.bgColor);
		bg.drawRect(0, 0, client.curLevel.pxWid, client.curLevel.pxHei);

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
			var above = new h2d.Flow(wrapper);
			above.layout = Vertical;
			above.horizontalAlign = Middle;

			var beneath = new h2d.Flow(wrapper);
			beneath.layout = Vertical;
			beneath.horizontalAlign = Middle;

			// Attach fields
			for(fd in ei.def.fieldDefs) {
				if( fd.editorDisplayMode==Hidden )
					continue;

				var fi = ei.getFieldInstance(fd);
				var fieldWrapper = new h2d.Object();
				switch fd.editorDisplayPos {
					case Above: above.addChild(fieldWrapper);
					case Beneath: beneath.addChild(fieldWrapper);
				}

				switch fd.editorDisplayMode {
					case Hidden: // N/A

					case NameAndValue:
						var tf = new h2d.Text(Assets.fontSmall, fieldWrapper);
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
								var tf = new h2d.Text(Assets.fontSmall, fieldWrapper);
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
			above.x = Std.int( -above.outerWidth*0.5 );
			above.y = Std.int( -above.outerHeight - bmp.tile.height*def.pivotY );

			beneath.x = Std.int( -beneath.outerWidth*0.5 );
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

		// Update scrolling
		root.setScale(zoom);
		root.x = w()*0.5 - focusLevelX * zoom;
		root.y = h()*0.5 - focusLevelY * zoom;

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
