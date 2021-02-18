package display;

enum FieldRenderContext {
	EntityCtx(g:h2d.Graphics, ei:data.inst.EntityInstance, ld:data.def.LayerDef);
	LevelCtx(l:data.Level);
}

class FieldInstanceRender {
	static var settings(get,never) : Settings; static inline function get_settings() return App.ME.settings;

	static function getDefaultFont() return Assets.fontLight_small;



	public static function addBg(f:h2d.Flow, baseColor:Int, darken=0.5) {
		var bg = new h2d.ScaleGrid( Assets.elements.getTile("fieldBg"), 2, 2 );
		f.addChildAt(bg, 0);
		f.getProperties(bg).isAbsolute = true;
		bg.color.setColor( C.addAlphaF( C.toBlack( baseColor, darken ) ) );
		bg.setPosition(0,0);
		bg.width = f.outerWidth;
		bg.height = f.outerHeight;
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


	public static function renderFields(fieldInstances:Array<data.inst.FieldInstance>, baseColor:Int, ctx:FieldRenderContext, parent:h2d.Flow) {
		var allRenders = [];

		// Detect errors
		for(fi in fieldInstances)
			if( fi.hasAnyErrorInValues() )
				baseColor = 0xff0000;

		// Create individual field renders
		for(fi in fieldInstances) {
			var fr = renderField(fi, baseColor, ctx);
			if( fr==null || fr.value.numChildren==0 )
				continue;

			allRenders.push(fr);
			var line = new h2d.Flow(parent);
			line.setScale( settings.v.editorUiScale );
			if( fr.label.numChildren>0 )
				line.addChild(fr.label);
			line.addChild(fr.value);
		}

		// Align everything and add BGs
		var maxLabelWidth = 0.;
		var maxValueWidth = 0.;
		for(fr in allRenders) {
			maxLabelWidth = M.fmax(maxLabelWidth, fr.label.outerWidth);
			maxValueWidth = M.fmax(maxValueWidth, fr.value.outerWidth);
		}
		for(fr in allRenders) {
			if( fr.label.numChildren>0 ) {
				fr.label.minWidth = Std.int( maxLabelWidth );
			}

			fr.value.minWidth = Std.int( maxValueWidth );
			if( fr.label.numChildren==0 )
				fr.value.minWidth += Std.int( maxLabelWidth);
			addBg(fr.value, baseColor, 0.5);

			if( fr.label.numChildren>0 )
				fr.label.minHeight = fr.value.outerHeight;
			addBg(fr.label, baseColor, 0.7);
		}
	}

	static function renderField(fi:data.inst.FieldInstance, baseColor:Int, ctx:FieldRenderContext) : Null<{ label:h2d.Flow, value:h2d.Flow }> {
		var fd = fi.def;

		var labelFlow = new h2d.Flow();
		labelFlow.verticalAlign = Middle;
		labelFlow.horizontalAlign = Right;
		labelFlow.padding = 6;

		var valueFlow = new h2d.Flow();
		valueFlow.padding = 6;

		// Value error
		var err = fi.getFirstErrorInValues();
		if( err!=null ) {
			var tf = new h2d.Text(getDefaultFont(), labelFlow);
			tf.textColor = baseColor;
			tf.text = fd.identifier;

			var tf = new h2d.Text(getDefaultFont(), valueFlow);
			tf.textColor = 0xff4400;
			tf.text = '<$err>';
			return { label:labelFlow, value:valueFlow };
		}

		// Skip hiddens
		if( fd.editorDisplayMode==Hidden )
			return null;

		if( !fi.def.editorAlwaysShow && ( fi.def.isArray && fi.getArrayLength()==0 || !fi.def.isArray && fi.isUsingDefault(0) ) )
			return null;

		switch fd.editorDisplayMode {
			case Hidden: // N/A

			case NameAndValue:
				// Label
				var tf = new h2d.Text(getDefaultFont(), labelFlow);
				tf.textColor = baseColor;
				tf.text = fd.identifier;

				// Value
				valueFlow.addChild( FieldInstanceRender.renderValue(fi, C.toWhite(baseColor, 0.8)) );

			case ValueOnly:
				valueFlow.addChild( FieldInstanceRender.renderValue(fi, C.toWhite(baseColor, 0.8)) );

			case RadiusPx:
				switch ctx {
					case EntityCtx(g,_):
						g.lineStyle(1, baseColor, 0.33);
						g.drawCircle(0,0, fi.def.type==F_Float ? fi.getFloat(0) : fi.getInt(0));

					case LevelCtx(_):
				}

			case RadiusGrid:
				switch ctx {
					case EntityCtx(g, ei, ld):
						g.lineStyle(1, baseColor, 0.33);
						g.drawCircle(0,0, ( fi.def.type==F_Float ? fi.getFloat(0) : fi.getInt(0) ) * ld.gridSize);

					case LevelCtx(_):
				}

			case EntityTile:

			case PointStar, PointPath:
				switch ctx {
					case EntityCtx(g, ei, ld):
						var fx = ei.getPointOriginX(ld) - ei.x;
						var fy = ei.getPointOriginY(ld) - ei.y;
						g.lineStyle(1, baseColor, 0.66);

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

					case LevelCtx(_):
						// TODO support points in level fields?
				}
		}

		return { label:labelFlow, value:valueFlow };
	}



	static function renderValue(fi:data.inst.FieldInstance, textColor:Int) : h2d.Flow {
		var valuesFlow = new h2d.Flow();
		valuesFlow.layout = Horizontal;
		valuesFlow.verticalAlign = Middle;

		// Array opening
		if( fi.def.isArray && fi.getArrayLength()>1 ) {
			var tf = new h2d.Text( getDefaultFont(), valuesFlow );
			tf.textColor = textColor;
			tf.text = "[";
		}

		// Empty array with "always" display
		if( fi.def.isArray && fi.getArrayLength()==0 && fi.def.editorAlwaysShow ) {
			var tf = new h2d.Text( getDefaultFont(), valuesFlow );
			tf.textColor = textColor;
			tf.text = "--empty--";
		}

		for( idx in 0...fi.getArrayLength() ) {
			if( fi.def.editorAlwaysShow || !fi.valueIsNull(idx) ) {
				if( fi.hasIconForDisplay(idx) ) {
					// Icon
					var w = new h2d.Flow(valuesFlow);
					var tile = fi.getIconForDisplay(idx);
					var bmp = new h2d.Bitmap( tile, w );
					var s = M.fmin( 32/tile.width, 32/tile.height );
					bmp.setScale(s);
				}
				else if( fi.def.type==F_Color ) {
					// Color disc
					var g = new h2d.Graphics(valuesFlow);
					var r = 12;
					g.beginFill( fi.getColorAsInt(idx) );
					g.lineStyle(1, 0x0, 0.8);
					g.drawCircle(r,r,r, 16);
				}
				else {
					// Text render
					var tf = new h2d.Text(getDefaultFont(), valuesFlow);
					tf.textColor = textColor;
					tf.maxWidth = 400 * ( 0.5 + 0.5*settings.v.editorUiScale );
					var v = fi.getForDisplay(idx);
					if( fi.def.type==F_Bool && fi.def.editorDisplayMode==ValueOnly )
						tf.text = '${fi.getBool(idx)?"+":"-"}${fi.def.identifier}';
					else {
						if( v==null )
							tf.text = "--null--";
						else if( fi.def.editorCutLongValues ) {
							var lines = v.substr(0,70).split("\n");
							var n = M.imin(2, lines.length);
							for(i in 0...n)
								tf.text+=lines[i] + (i<n-1 ? "\n" : "");
						}
						else
							tf.text = v;
					}
				}
			}

			// Array separator
			if( fi.def.isArray && idx<fi.getArrayLength()-1 ) {
				var tf = new h2d.Text(getDefaultFont(), valuesFlow);
				tf.textColor = textColor;
				tf.text = ",";
			}
		}

		// Array closing
		if( fi.def.isArray && fi.getArrayLength()>1 ) {
			var tf = new h2d.Text(getDefaultFont(), valuesFlow);
			tf.textColor = textColor;
			tf.text = "]";
		}

		return valuesFlow;
	}


}