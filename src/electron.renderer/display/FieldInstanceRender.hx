package display;

enum FieldRenderContext {
	EntityCtx(g:h2d.Graphics, ei:data.inst.EntityInstance, ld:data.def.LayerDef);
}

class FieldInstanceRender {
	static var settings(get,never) : Settings; static inline function get_settings() return App.ME.settings;

	static function getDefaultFont() return Assets.fontLight_small;



	static inline function addBg(f:h2d.Flow, textColor:Int) {
		var bg = new h2d.ScaleGrid( Assets.elements.getTile("fieldBg"), 2, 2 );
		f.addChildAt(bg, 0);
		f.getProperties(bg).isAbsolute = true;
		bg.color.setColor( C.addAlphaF( C.toBlack( textColor, 0.5 ) ) );
		bg.alpha = 0.9;
		bg.x = -8;
		bg.y = 1;
		bg.width = f.outerWidth + M.fabs(bg.x)*2;
		bg.height = f.outerHeight+3;
	}


	static inline function renderDashedLine(g:h2d.Graphics, fx:Float, fy:Float, tx:Float, ty:Float, dashLen=4.) {
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


	public static function renderField(fi:data.inst.FieldInstance, textColor:Int, ?ctx:FieldRenderContext) : Null<h2d.Flow> {
		var fd = fi.def;
		var fieldWrapper = new h2d.Flow();

		// Value error
		var err = fi.getFirstErrorInValues();
		if( err!=null ) {
			var tf = new h2d.Text(getDefaultFont(), fieldWrapper);
			tf.scale(settings.v.editorUiScale);
			tf.textColor = 0xff8800;
			tf.text = '<$err>';
			return fieldWrapper;
		}

		// Skip hiddens
		if( fd.editorDisplayMode==Hidden )
			return null;

		if( !fi.def.editorAlwaysShow && ( fi.def.isArray && fi.getArrayLength()==0 || !fi.def.isArray && fi.isUsingDefault(0) ) )
			return null;

		switch fd.editorDisplayMode {
			case Hidden: // N/A

			case NameAndValue:
				var f = new h2d.Flow(fieldWrapper);
				f.verticalAlign = Middle;

				var tf = new h2d.Text(getDefaultFont(), f);
				tf.scale(settings.v.editorUiScale);
				tf.textColor = textColor;
				tf.text = fd.identifier+" = ";

				f.addChild( FieldInstanceRender.renderValue(fi, textColor) );

			case ValueOnly:
				fieldWrapper.addChild( FieldInstanceRender.renderValue(fi, textColor) );

			case RadiusPx:
				switch ctx {
					case null:
					case EntityCtx(g,_):
						g.lineStyle(1, textColor, 0.33);
						g.drawCircle(0,0, fi.def.type==F_Float ? fi.getFloat(0) : fi.getInt(0));
				}

			case RadiusGrid:
				switch ctx {
					case null:
					case EntityCtx(g, ei, ld):
						g.lineStyle(1, textColor, 0.33);
						g.drawCircle(0,0, ( fi.def.type==F_Float ? fi.getFloat(0) : fi.getInt(0) ) * ld.gridSize);
				}

			case EntityTile:

			case PointStar, PointPath:
				switch ctx {
					case null:
					case EntityCtx(g, ei, ld):
						var fx = ei.getCellCenterX(ld);
						var fy = ei.getCellCenterY(ld);
						g.lineStyle(1, textColor, 0.66);

						for(i in 0...fi.getArrayLength()) {
							var pt = fi.getPointGrid(i);
							if( pt==null )
								continue;

							var tx = M.round( (pt.cx+0.5)*ld.gridSize - ei.x );
							var ty = M.round( (pt.cy+0.5)*ld.gridSize - ei.y );
							renderDashedLine(g, fx,fy, tx,ty, 3);
							g.drawRect( tx-2, ty-2, 4, 4 );

							if( fd.editorDisplayMode==PointPath ) {
								fx = tx;
								fy = ty;
							}
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
			case F_String, F_Text, F_Bool, F_Path: true;
			case F_Color: fd.editorDisplayMode==NameAndValue;
			case F_Point: false;
			case F_Enum(enumDefUid): fd.editorDisplayMode!=EntityTile;
		}

		if( needBg )
			addBg(fieldWrapper, textColor);

		fieldWrapper.visible = fieldWrapper.numChildren>0;

		return fieldWrapper;
	}


	public static function renderValue(fi:data.inst.FieldInstance, textColor:Int) {
		var valuesFlow = new h2d.Flow();
		valuesFlow.layout = Horizontal;
		valuesFlow.verticalAlign = Middle;

		// Array opening
		if( fi.def.isArray && fi.getArrayLength()>1 ) {
			var tf = new h2d.Text(getDefaultFont(), valuesFlow);
			tf.scale(settings.v.editorUiScale);
			tf.textColor = textColor;
			tf.text = "[";
		}

		for( idx in 0...fi.getArrayLength() ) {
			if( !fi.valueIsNull(idx) && !( !fi.def.editorAlwaysShow && fi.def.type==F_Bool && fi.isUsingDefault(idx) ) ) {
				if( fi.hasIconForDisplay(idx) ) {
					// Icon
					var w = new h2d.Flow(valuesFlow);
					var tile = fi.getIconForDisplay(idx);
					var bmp = new h2d.Bitmap( tile, w );
					var s = M.fmin( 32/tile.width, 32/tile.height );
					bmp.setScale(s * settings.v.editorUiScale);
				}
				else if( fi.def.type==F_Color ) {
					// Color disc
					var g = new h2d.Graphics(valuesFlow);
					var r = 12 * settings.v.editorUiScale;
					g.beginFill( fi.getColorAsInt(idx) );
					g.lineStyle(1, 0x0, 0.8);
					g.drawCircle(r,r,r, 16);
				}
				else {
					// Text render
					var tf = new h2d.Text(getDefaultFont(), valuesFlow);
					tf.scale(settings.v.editorUiScale);
					tf.textColor = textColor;
					tf.maxWidth = 400 * ( 0.5 + 0.5*settings.v.editorUiScale );
					var v = fi.getForDisplay(idx);
					if( fi.def.type==F_Bool && fi.def.editorDisplayMode==ValueOnly )
						tf.text = '${fi.getBool(idx)?"+":"-"}${fi.def.identifier}';
					else
						tf.text = v;
				}
			}

			// Array separator
			if( fi.def.isArray && idx<fi.getArrayLength()-1 ) {
				var tf = new h2d.Text(getDefaultFont(), valuesFlow);
				tf.scale(settings.v.editorUiScale);
				tf.textColor = textColor;
				tf.text = ",";
			}
		}

		// Array closing
		if( fi.def.isArray && fi.getArrayLength()>1 ) {
			var tf = new h2d.Text(getDefaultFont(), valuesFlow);
			tf.scale(settings.v.editorUiScale);
			tf.textColor = textColor;
			tf.text = "]";
		}

		return valuesFlow;
	}


}