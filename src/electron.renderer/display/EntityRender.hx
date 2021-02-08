package display;


class EntityRender extends dn.Process {
	var ei : data.inst.EntityInstance;
	var ed(get,never) : data.def.EntityDef; inline function get_ed() return ei.def;
	var settings(get,never) : Settings; inline function get_settings() return App.ME.settings;

	var ld : data.def.LayerDef;

	var core: h2d.Object;

	// Field wrappers
	var above: h2d.Flow;
	var center: h2d.Flow;
	var beneath: h2d.Flow;
	var fieldGraphics : h2d.Graphics;

	public var posInvalidated = true;


	public function new(inst:data.inst.EntityInstance, layerDef:data.def.LayerDef, p:h2d.Object) {
		super(Editor.ME);

		createRoot(p);
		ei = inst;
		ld = layerDef;

		core = new h2d.Object(root);

		fieldGraphics = new h2d.Graphics(root);

		above = new h2d.Flow(root);
		above.layout = Vertical;
		above.horizontalAlign = Middle;
		above.verticalSpacing = 1;

		center = new h2d.Flow(root);
		center.layout = Vertical;
		center.horizontalAlign = Middle;
		center.verticalSpacing = 1;

		beneath = new h2d.Flow(root);
		beneath.layout = Vertical;
		beneath.horizontalAlign = Middle;
		beneath.verticalSpacing = 1;

		renderAll();
	}

	override function onDispose() {
		super.onDispose();
		ei = null;
		ld = null;
		above = null;
		beneath = null;
		center = null;
		fieldGraphics = null;
		core = null;
	}


	public function onViewportChange() {
		posInvalidated = true;
	}

	public function onLayerSelection() {
		posInvalidated = true;
	}


	public static function renderCore(?ei:data.inst.EntityInstance, ?ed:data.def.EntityDef) : h2d.Object {
		if( ei==null && ed==null )
			throw "Need at least 1 parameter";

		if( ed==null )
			ed = ei.def;

		var wrapper = new h2d.Object();

		var g = new h2d.Graphics(wrapper);
		g.x = Std.int( -ed.width*ed.pivotX );
		g.y = Std.int( -ed.height*ed.pivotY );

		// Render a tile
		function renderTile(tilesetId:Null<Int>, tileId:Null<Int>, mode:ldtk.Json.EntityTileRenderMode) {
			if( tileId==null || tilesetId==null ) {
				// Missing tile
				var p = 2;
				g.lineStyle(3, 0xff0000);
				g.moveTo(p,p);
				g.lineTo(ed.width-p, ed.height-p);
				g.moveTo(ed.width-p, p);
				g.lineTo(p, ed.height-p);
			}
			else {
				g.beginFill(ed.color, 0.2);
				g.drawRect(0, 0, ed.width, ed.height);

				var td = Editor.ME.project.defs.getTilesetDef(tilesetId);
				var t = td.getTile(tileId);
				var bmp = new h2d.Bitmap(t, wrapper);
				switch mode {
					case Stretch:
						bmp.scaleX = ed.width / bmp.tile.width;
						bmp.scaleY = ed.height / bmp.tile.height;

					case Crop:
						if( bmp.tile.width>ed.width || bmp.tile.height>ed.height )
							bmp.tile = bmp.tile.sub(
								0, 0,
								M.fmin( bmp.tile.width, ed.width ),
								M.fmin( bmp.tile.height, ed.height )
							);
				}
				bmp.tile.setCenterRatio(ed.pivotX, ed.pivotY);
			}
		}

		// Base render
		var custTile = ei==null ? null : ei.getSmartTile();
		if( custTile!=null )
			renderTile(custTile.tilesetUid, custTile.tileId, Stretch);
		else
			switch ed.renderMode {
			case Rectangle, Ellipse:
				g.beginFill(ed.color);
				g.lineStyle(1, 0x0, 0.4);
				switch ed.renderMode {
					case Rectangle:
						g.drawRect(0, 0, ed.width, ed.height);

					case Ellipse:
						g.drawEllipse(ed.width*0.5, ed.height*0.5, ed.width*0.5, ed.height*0.5, 0, ed.width<=16 || ed.height<=16 ? 16 : 0);

					case _:
				}
				g.endFill();

			case Cross:
				g.lineStyle(5, ed.color, 1);
				g.moveTo(0,0);
				g.lineTo(ed.width, ed.height);
				g.moveTo(0,ed.height);
				g.lineTo(ed.width, 0);

			case Tile:
				renderTile(ed.tilesetId, ed.tileId, ed.tileRenderMode);
			}

		// Pivot
		g.beginFill(ed.color);
		g.lineStyle(1, 0x0, 0.5);
		var pivotSize = 3;
		g.drawRect(
			Std.int((ed.width-pivotSize)*ed.pivotX),
			Std.int((ed.height-pivotSize)*ed.pivotY),
			pivotSize, pivotSize
		);

		return wrapper;
	}


	public function renderAll() {
		core.removeChildren();
		core.addChild( renderCore(ei,ed) );

		renderFields();
	}


	inline function renderDashedLine(g:h2d.Graphics, fx:Float, fy:Float, tx:Float, ty:Float, dashLen=4.) {
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


	inline function getDefaultFont() {
		return Editor.ME.camera.pixelRatio<=1 ? Assets.fontLight_tiny : Assets.fontLight_small;
	}


	inline function addFieldBg(f:h2d.Flow, dark:Float) {
		var bg = new h2d.ScaleGrid(Assets.elements.getTile("fieldBg"), 2,2);
		f.addChildAt(bg, 0);
		f.getProperties(bg).isAbsolute = true;
		bg.color.setColor( C.addAlphaF( C.toBlack( ei.getSmartColor(false), dark ) ) );
		bg.alpha = 0.9;
		bg.x = -8;
		bg.y = 1;
		bg.width = f.outerWidth + M.fabs(bg.x)*2;
		bg.height = f.outerHeight+3;
	}



	// function renderFieldValue(fi:data.inst.FieldInstance) {
	// 	var valuesFlow = new h2d.Flow();
	// 	valuesFlow.layout = Horizontal;
	// 	valuesFlow.verticalAlign = Middle;

	// 	// Array opening
	// 	if( fi.def.isArray && fi.getArrayLength()>1 ) {
	// 		var tf = new h2d.Text(getDefaultFont(), valuesFlow);
	// 		tf.scale(settings.v.editorUiScale);
	// 		tf.textColor = ei.getSmartColor(true);
	// 		tf.text = "[";
	// 	}

	// 	for( idx in 0...fi.getArrayLength() ) {
	// 		if( !fi.valueIsNull(idx) && !( !fi.def.editorAlwaysShow && fi.def.type==F_Bool && fi.isUsingDefault(idx) ) ) {
	// 			if( fi.hasIconForDisplay(idx) ) {
	// 				// Icon
	// 				var w = new h2d.Flow(valuesFlow);
	// 				var tile = fi.getIconForDisplay(idx);
	// 				var bmp = new h2d.Bitmap( tile, w );
	// 				var s = M.fmin( 32/tile.width, 32/tile.height );
	// 				bmp.setScale(s * settings.v.editorUiScale);
	// 			}
	// 			else if( fi.def.type==F_Color ) {
	// 				// Color disc
	// 				var g = new h2d.Graphics(valuesFlow);
	// 				var r = 6;
	// 				g.beginFill( fi.getColorAsInt(idx) );
	// 				g.lineStyle(1, 0x0, 0.8);
	// 				g.drawCircle(r,r,r, 16);
	// 			}
	// 			else {
	// 				// Text render
	// 				var tf = new h2d.Text(getDefaultFont(), valuesFlow);
	// 				tf.scale(settings.v.editorUiScale);
	// 				tf.textColor = ei.getSmartColor(true);
	// 				tf.maxWidth = 400 * ( 0.5 + 0.5*settings.v.editorUiScale );
	// 				var v = fi.getForDisplay(idx);
	// 				if( fi.def.type==F_Bool && fi.def.editorDisplayMode==ValueOnly )
	// 					tf.text = '${fi.getBool(idx)?"+":"-"}${fi.def.identifier}';
	// 				else
	// 					tf.text = v;
	// 			}
	// 		}

	// 		// Array separator
	// 		if( fi.def.isArray && idx<fi.getArrayLength()-1 ) {
	// 			var tf = new h2d.Text(getDefaultFont(), valuesFlow);
	// 			tf.scale(settings.v.editorUiScale);
	// 			tf.textColor = ei.getSmartColor(true);
	// 			tf.text = ",";
	// 		}
	// 	}

	// 	// Array closing
	// 	if( fi.def.isArray && fi.getArrayLength()>1 ) {
	// 		var tf = new h2d.Text(getDefaultFont(), valuesFlow);
	// 		tf.scale(settings.v.editorUiScale);
	// 		tf.textColor = ei.getSmartColor(true);
	// 		tf.text = "]";
	// 	}

	// 	return valuesFlow;
	// }


	public function renderFields() {
		above.removeChildren();
		center.removeChildren();
		beneath.removeChildren();
		fieldGraphics.clear();

		// Attach fields
		for(fd in ei.def.fieldDefs) {
			var fi = ei.getFieldInstance(fd);
			var fr = FieldInstanceRender.renderField(fi, ei.getSmartColor(true), EntityCtx(fieldGraphics,ei,ld));

			if( fr==null )
				continue;

			// Position
			switch fd.editorDisplayPos {
				case Above: above.addChild(fr);
				case Center: center.addChild(fr);
				case Beneath: beneath.addChild(fr);
			}
		}

		// Identifier label
		if( ei.def.showName ) {
			var f = new h2d.Flow(above);
			var tf = new h2d.Text(getDefaultFont(), f);
			tf.scale(settings.v.editorUiScale);
			tf.textColor = ei.getSmartColor(true);
			tf.text = ed.identifier.substr(0,16);
			tf.x = Std.int( ed.width*0.5 - tf.textWidth*tf.scaleX*0.5 );
			tf.y = 0;
			addFieldBg(f, 0.5);
		}

		updatePos();
	}

	public inline function updatePos() {
		posInvalidated = false;
		var cam = Editor.ME.camera;
		var downScale = M.fclamp( (3-cam.adjustedZoom)*0.3, 0, 0.8 );
		var scale = (1-downScale) / cam.adjustedZoom;
		var alpha = M.fclamp( (cam.adjustedZoom-0.33*cam.pixelRatio) / 3, 0, 1 );

		root.x = ei.x;
		root.y = ei.y;

		// Hide fields in other layers
		if( Editor.ME.curLayerDef==null || Editor.ME.curLayerDef.type!=Entities )
			alpha*=0.4;
		// above.visible = center.visible = beneath.visible = Editor.ME.curLayerDef.type==Entities;

		// Update field wrappers
		above.setScale(scale);
		above.x = Std.int( -ed.width*ed.pivotX - above.outerWidth*0.5*above.scaleX + ed.width*0.5 );
		above.y = Std.int( -above.outerHeight*above.scaleY - ed.height*ed.pivotY - 1 );
		above.alpha = alpha;

		center.setScale(scale);
		center.x = Std.int( -ed.width*ed.pivotX - center.outerWidth*0.5*center.scaleX + ed.width*0.5 );
		center.y = Std.int( -ed.height*ed.pivotY - center.outerHeight*0.5*center.scaleY + ed.height*0.5);
		center.alpha = alpha;

		beneath.setScale(scale);
		beneath.x = Std.int( -ed.width*ed.pivotX - beneath.outerWidth*0.5*beneath.scaleX + ed.width*0.5 );
		beneath.y = Std.int( ed.height*(1-ed.pivotY) + 1 );
		beneath.alpha = alpha;
	}

	override function update() {
		super.update();
		if( posInvalidated )
			updatePos();
	}
}