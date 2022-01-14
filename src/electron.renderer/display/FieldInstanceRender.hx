package display;

enum FieldRenderContext {
	EntityCtx(g:h2d.Graphics, ei:data.inst.EntityInstance, ld:data.def.LayerDef);
	LevelCtx(l:data.Level);
}

class FieldInstanceRender {
	static var settings(get,never) : Settings; static inline function get_settings() return App.ME.settings;


	public static function addBg(f:h2d.Flow, baseColor:Int, darken=0.5) {
		var bg = new h2d.Bitmap( h2d.Tile.fromColor( C.toBlack(baseColor,darken), 1,1, 0.92 ) );
		f.addChildAt(bg, 0);
		f.getProperties(bg).isAbsolute = true;
		bg.scaleX = f.outerWidth;
		bg.scaleY = f.outerHeight+1;
	}


	public static inline function renderRefLink(g:h2d.Graphics, color:Int, fx:Float, fy:Float, tx:Float, ty:Float) {
		var a = Math.atan2(ty-fy, tx-fx);
		var len = M.dist(fx,fy, tx,ty);
		var dashLen = M.fmin(5, len*0.05);
		var count = M.ceil( len/dashLen );
		dashLen = len/count;

		var n = 0;
		var sign = 1;
		final off = 2.5;
		var x = fx;
		var y = fy;
		while( n<count ) {
			final r = n/(count-1);
			final startRatio = M.fmin(r/0.05, 1);
			g.lineStyle(1, color, 0.15 + 0.85*(1-r));
			g.moveTo(x,y);
			x = fx+Math.cos(a)*(n*dashLen) + Math.cos(a+M.PIHALF)*sign*off*(1-r)*startRatio;
			y = fy+Math.sin(a)*(n*dashLen) + Math.sin(a+M.PIHALF)*sign*off*(1-r)*startRatio;
			g.lineTo(x,y);
			sign = -sign;
			n++;
		}
		g.lineTo(tx,ty);
	}


	static inline function renderSimpleLink(g:h2d.Graphics, color:Int, fx:Float, fy:Float, tx:Float, ty:Float, dashLen=10.) {
		var a = Math.atan2(ty-fy, tx-fx);
		var len = M.dist(fx,fy, tx,ty);
		var count = M.ceil( len/dashLen );
		dashLen = len/count;

		var n = 0;
		var sign = 1;
		final off = 0.7;
		var x = fx;
		var y = fy;
		while( n<count ) {
			final r = n/(count-1);
			g.lineStyle(1, color, 0.4 + 0.6*(1-r));
			g.moveTo(x,y);
			x = fx+Math.cos(a)*(n*dashLen) + Math.cos(a+M.PIHALF)*sign*off;
			y = fy+Math.sin(a)*(n*dashLen) + Math.sin(a+M.PIHALF)*sign*off;
			g.lineTo(x,y);
			sign = -sign;
			n++;
		}
		g.lineTo(tx,ty);
	}


	public static function renderFields(fieldInstances:Array<data.inst.FieldInstance>, baseColor:Int, ctx:FieldRenderContext, parent:h2d.Flow) {
		var allRenders = [];

		var ei = switch ctx {
			case EntityCtx(g, ei, ld): ei;
			case LevelCtx(l): null;
		}

		// Detect errors
		for(fi in fieldInstances)
			if( fi.hasAnyErrorInValues(ei) )
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
			if( fr.label.numChildren>0 )
				fr.label.minWidth = Std.int( maxLabelWidth );

			fr.value.minWidth = Std.int( maxValueWidth );
			if( fr.label.numChildren==0 )
				fr.value.minWidth += Std.int( maxLabelWidth);
			addBg(fr.value, baseColor, 0.75);

			if( fr.label.numChildren>0 ) {
				fr.label.minHeight = fr.value.outerHeight;
				addBg(fr.label, baseColor, 0.88);
			}
		}
	}


	static inline function createText(target:h2d.Object) {
		var tf = new h2d.Text(Assets.getRegularFont(), target);
		tf.smooth = true;
		return tf;
	}

	static function renderField(fi:data.inst.FieldInstance, baseColor:Int, ctx:FieldRenderContext) : Null<{ label:h2d.Flow, value:h2d.Flow }> {
		var fd = fi.def;

		var labelFlow = new h2d.Flow();
		labelFlow.verticalAlign = Middle;
		labelFlow.horizontalAlign = Right;
		labelFlow.padding = 6;

		var valueFlow = new h2d.Flow();
		valueFlow.padding = 6;

		var ei = switch ctx {
			case EntityCtx(g, ei, ld): ei;
			case LevelCtx(l): null;
		}

		// Value error
		var err = fi.getFirstErrorInValues(ei);
		if( err!=null ) {
			var tf = createText(labelFlow);
			tf.textColor = baseColor;
			tf.text = fd.identifier;

			var tf = createText(valueFlow);
			tf.textColor = 0xff4400;
			tf.text = '<$err>';
		}

		// Skip hiddens
		if( err==null && fd.editorDisplayMode==Hidden )
			return null;

		if( err==null && !fi.def.editorAlwaysShow && ( fi.def.isArray && fi.getArrayLength()==0 || !fi.def.isArray && fi.isUsingDefault(0) ) )
			return null;

		switch fd.editorDisplayMode {
			case Hidden: // N/A

			case NameAndValue:
				// Label
				var tf = createText(labelFlow);
				tf.textColor = baseColor;
				tf.text = fd.identifier;

				// Value
				valueFlow.addChild( FieldInstanceRender.renderValue(ctx, fi, C.toWhite(baseColor, 0.8)) );

			case ValueOnly:
				valueFlow.addChild( FieldInstanceRender.renderValue(ctx, fi, C.toWhite(baseColor, 0.8)) );

			case ArrayCountWithLabel:
				// Label
				var tf = createText(labelFlow);
				tf.textColor = baseColor;
				tf.text = fd.identifier;

				// Value
				var tf = createText(valueFlow);
				tf.textColor = baseColor;
				tf.text = '${fi.getArrayLength()} value(s)';

			case ArrayCountNoLabel:
				var tf = createText(valueFlow);
				tf.textColor = baseColor;
				tf.text = '${fi.getArrayLength()} value(s)';

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

			case RefLink:
				switch ctx {
					case EntityCtx(g, ei, ld):
						var fx = ei.centerX - ei.x;
						var fy = ei.centerY - ei.y;
						for(i in 0...fi.getArrayLength()) {
							var tei = fi.getEntityRefInstance(i);
							if( tei==null )
								continue;
							var tx = M.round( tei.centerX + tei._li.level.worldX - ( ei.x + ei._li.level.worldX ) );
							var ty = M.round( tei.centerY + tei._li.level.worldY - ( ei.y + ei._li.level.worldY ) );
							renderRefLink(g, baseColor, fx,fy, tx,ty);
						}

					case LevelCtx(l):
				}


			case Points, PointStar, PointPath, PointPathLoop:
				switch ctx {
					case EntityCtx(g, ei, ld):
						var fx = ei.getPointOriginX(ld) - ei.x;
						var fy = ei.getPointOriginY(ld) - ei.y;
						var startX = fx;
						var startY = fy;

						for(i in 0...fi.getArrayLength()) {
							var pt = fi.getPointGrid(i);
							if( pt==null )
								continue;

							var tx = M.round( (pt.cx+0.5)*ld.gridSize - ei.x );
							var ty = M.round( (pt.cy+0.5)*ld.gridSize - ei.y );
							if( fd.editorDisplayMode!=Points )
								renderSimpleLink(g, baseColor, fx,fy, tx,ty);

							g.lineStyle(1, baseColor, 0.66);
							g.beginFill( C.toBlack(baseColor, 0.6) );
							final s = 4;
							g.moveTo(tx, ty-s);
							g.lineTo(tx+s, ty);
							g.lineTo(tx, ty+s);
							g.lineTo(tx-s, ty);
							g.lineTo(tx, ty-s);
							g.endFill();

							switch fd.editorDisplayMode {
								case Hidden, ValueOnly, NameAndValue, EntityTile, RadiusPx, RadiusGrid, ArrayCountNoLabel, ArrayCountWithLabel:
								case Points, PointStar:
								case RefLink:
								case PointPath, PointPathLoop:
									// Next point connects to this one
									fx = tx;
									fy = ty;
							}
						}

						// Loop to Entity
						if( fd.editorDisplayMode==PointPathLoop && fi.getArrayLength()>1 )
							renderSimpleLink(g, baseColor, fx,fy, startX, startY);

					case LevelCtx(_):
				}
		}

		return { label:labelFlow, value:valueFlow };
	}



	static function renderValue(ctx:FieldRenderContext, fi:data.inst.FieldInstance, textColor:Int) : h2d.Flow {
		var valuesFlow = new h2d.Flow();
		valuesFlow.layout = Horizontal;
		valuesFlow.verticalAlign = Middle;

		var multiLinesArray = fi.def.isArray && switch fi.def.type {
			case F_Int: false;
			case F_Float: false;
			case F_String: true;
			case F_Text: true;
			case F_Bool: false;
			case F_Color: false;
			case F_Enum(enumDefUid): false;
			case F_Point: false;
			case F_Path: true;
			case F_EntityRef: true;
		}
		if( multiLinesArray ) {
			valuesFlow.multiline = true;
			valuesFlow.maxWidth = 200;
		}

		// Array opening
		if( fi.def.isArray && fi.getArrayLength()>1 ) {
			var tf = createText(valuesFlow);
			tf.textColor = textColor;
			tf.text = "[";
		}

		// Empty array with "always" display
		if( fi.def.isArray && fi.getArrayLength()==0 && fi.def.editorAlwaysShow ) {
			var tf = createText(valuesFlow);
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
					var tf = createText(valuesFlow);
					tf.textColor = textColor;
					switch ctx {
						case EntityCtx(g, ei, ld):
							tf.maxWidth = 400;

						case LevelCtx(l):
							tf.maxWidth = 800;
					}
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
				var tf = createText(valuesFlow);
				tf.textColor = textColor;
				tf.text = ",";
			}
		}

		// Array closing
		if( fi.def.isArray && fi.getArrayLength()>1 ) {
			var tf = createText(valuesFlow);
			tf.textColor = textColor;
			tf.text = "]";
		}

		return valuesFlow;
	}


}