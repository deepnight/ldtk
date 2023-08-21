package display;

enum LinkEndingStyle {
	Full;
	CutAtOrigin;
	CutAtTarget;
}

enum FieldRenderContext {
	EntityCtx(g:h2d.Graphics, ei:data.inst.EntityInstance, ld:data.def.LayerDef);
	LevelCtx(l:data.Level);
}

typedef RenderedField = {
	var label : h2d.Flow;
	var value : h2d.Flow;
}

class FieldInstanceRender {
	static var MAX_TEXT_WIDTH = 250;
	static var settings(get,never) : Settings;
		static inline function get_settings() return App.ME.settings;

	static var pixelRatio(get,never) : Float;
		static inline function get_pixelRatio() return Editor.ME.camera.pixelRatio;

	static var zoomScale(get,never) : Float;
		static inline function get_zoomScale() return Editor.ME.camera.pixelRatio / Editor.ME.camera.adjustedZoom;


	public static inline function renderRefLink(g:h2d.Graphics, color:Int, fx:Float, fy:Float, tx:Float, ty:Float, alpha:Float, linkStyle:ldtk.Json.FieldLinkStyle, endingStyle:LinkEndingStyle) {
		var len = M.dist(fx,fy, tx,ty);

		// Slightly offset the reflink end point
		if( endingStyle==null || endingStyle==Full )
			switch linkStyle {
				case ZigZag:
				case DashedLine:
				case ArrowsLine:
					if( len>=12 ) {
						var a = Math.atan2(ty-fy, tx-fx);
						fx+=Math.cos(a)*3;
						fy+=Math.sin(a)*3;
						tx-=Math.cos(a)*4;
						ty-=Math.sin(a)*4;
					}

				case StraightArrow, CurvedArrow:
					if( len>=20 ) {
						var a = Math.atan2(ty-fy, tx-fx);
						tx-=Math.cos(a)*4;
						ty-=Math.sin(a)*4;
					}
			}

		// Render line
		renderSimpleLink(g, color, fx,fy, tx,ty, linkStyle, endingStyle);
	}


	static inline function renderSimpleLink(g:h2d.Graphics, color:Int, fx:Float, fy:Float, tx:Float, ty:Float, linkStyle:ldtk.Json.FieldLinkStyle, ?endingStyle:LinkEndingStyle) {
		var dashLen = 4.;
		var alpha = 1;
		var a = Math.atan2(ty-fy, tx-fx);

		// Optional line cutting
		final cutDist = M.fmin(60, M.dist(fx,fy, tx,ty));
		switch endingStyle {
			case null:

			case Full:

			case CutAtOrigin:
				final cutLine = 4;
				tx = fx + Math.cos(a)*cutDist;
				ty = fy + Math.sin(a)*cutDist;
				g.lineStyle(1*zoomScale, color, 0.5);
				g.moveTo(tx + Math.cos(a-M.PIHALF)*cutLine, ty + Math.sin(a-M.PIHALF)*cutLine);
				g.lineTo(tx + Math.cos(a+M.PIHALF)*cutLine, ty + Math.sin(a+M.PIHALF)*cutLine);

			case CutAtTarget:
				final cutLine = 4;
				fx = tx - Math.cos(a)*cutDist;
				fy = ty - Math.sin(a)*cutDist;
				g.lineStyle(1*zoomScale, color, 1);
				g.moveTo(fx + Math.cos(a-M.PIHALF)*cutLine, fy + Math.sin(a-M.PIHALF)*cutLine);
				g.lineTo(fx + Math.cos(a+M.PIHALF)*cutLine, fy + Math.sin(a+M.PIHALF)*cutLine);
		}

		// Other inits
		var len = M.dist(fx,fy, tx,ty);
		var count = M.fclamp( len/dashLen, 8, 30);
		dashLen = len/count;

		// Draw link
		var n = 0;
		switch linkStyle {
			case ZigZag:
				var sign = 1;
				final zigZagOff = 2.1;
				var x = fx;
				var y = fy;
				while( n<count ) {
					final r = n/(count-1);
					final startRatio = M.fmin(r/0.05, 1);
					g.lineStyle((2-r)*zoomScale, color, ( 0.3 + 0.7*(1-r) ) * alpha );
					g.moveTo(x,y);
					x = fx+Math.cos(a)*(n*dashLen) + Math.cos(a+M.PIHALF)*sign*zigZagOff*(1-r)*startRatio;
					y = fy+Math.sin(a)*(n*dashLen) + Math.sin(a+M.PIHALF)*sign*zigZagOff*(1-r)*startRatio;
					g.lineTo(x,y);
					sign = -sign;
					n++;
				}
				g.lineTo(tx,ty);

			case ArrowsLine:
				dashLen = 16 * zoomScale;
				count = len/dashLen;

				var x = fx;
				var y = fy;
				var arrowSize = 9 * zoomScale;
				var arrowAng = M.PI*0.75;
				while( n<count ) {
					final r = n/(count-1);
					final startRatio = M.fmin(r/0.05, 1);
					g.lineStyle((4-2*r)*zoomScale, color, ( 0.5 + 0.5*(1-r) ) * alpha );
					x = fx+Math.cos(a)*(n*dashLen);
					y = fy+Math.sin(a)*(n*dashLen);
					g.moveTo( x+Math.cos(a+arrowAng)*arrowSize, y+Math.sin(a+arrowAng)*arrowSize);
					g.lineTo( x, y );
					g.lineTo( x+Math.cos(a-arrowAng)*arrowSize, y+Math.sin(a-arrowAng)*arrowSize);
					n++;
				}

			case DashedLine:
				var x = fx;
				var y = fy;
				var arrowSize = 6*zoomScale;
				while( n<count ) {
					final r = n/(count-1);
					final startRatio = M.fmin(r/0.05, 1);
					g.lineStyle((4-r*2)*zoomScale, color, ( 0.4 + 0.6*(1-r) ) * alpha );
					g.moveTo(x,y);
					g.lineTo( x+Math.cos(a)*dashLen*0.6, y+Math.sin(a)*dashLen*0.6 );
					x = fx+Math.cos(a)*(n*dashLen);
					y = fy+Math.sin(a)*(n*dashLen);
					n++;
				}

			case CurvedArrow:
				// Arrow line
				var x = fx;
				var y = fy;
				final curveOff = M.fclamp(len/200, 2, 15);
				var lastAng = 0.;
				while( n<count ) {
					final r = n/(count-1);
					final startRatio = M.fmin(r/0.05, 1);
					g.lineStyle((1+r*3)*zoomScale, color, ( 0.4 + 0.6*r ) * alpha );
					g.moveTo(x,y);
					var lastX = x;
					var lastY = y;
					x = fx + Math.cos(a)*(n*dashLen);
					y = fy + Math.sin(a)*(n*dashLen);
					x += curveOff * Math.cos(a+M.PIHALF) * Math.sin(r*M.PI);
					y += curveOff * Math.sin(a+M.PIHALF) * Math.sin(r*M.PI);
					lastAng = Math.atan2(y-lastY, x-lastX);
					g.lineTo(x,y);
					n++;
				}

				// Arrow head
				final size = ( len<=32 ? 10 : 12 ) * zoomScale;
				var headAng = M.PI*0.8;
				g.lineStyle(0);
				g.beginFill(color,1);
				g.moveTo( x+Math.cos(lastAng+headAng)*size, y+Math.sin(lastAng+headAng)*size );
				g.lineTo( x+Math.cos(lastAng)*2*zoomScale, y+Math.sin(lastAng)*2*zoomScale );
				g.lineTo( x+Math.cos(lastAng-headAng)*size, y+Math.sin(lastAng-headAng)*size );
				g.endFill();

			case StraightArrow:
				// Arrow line
				var x = fx;
				var y = fy;
				while( n<count ) {
					final r = n/(count-1);
					final startRatio = M.fmin(r/0.05, 1);
					g.lineStyle((1+r*3)*zoomScale, color, ( 0.4 + 0.6*r ) * alpha );
					g.moveTo(x,y);
					x = fx + Math.cos(a)*(n*dashLen);
					y = fy + Math.sin(a)*(n*dashLen);
					g.lineTo(x,y);
					n++;
				}

				// Arrow head
				final size = ( len<=32 ? 10 : 12 ) * zoomScale;
				var headAng = M.PI*0.8;
				g.lineStyle(0);
				g.beginFill(color,1);
				g.moveTo( x+Math.cos(a+headAng)*size, y+Math.sin(a+headAng)*size );
				g.lineTo( x+Math.cos(a)*2*zoomScale, y+Math.sin(a)*2*zoomScale );
				g.lineTo( x+Math.cos(a-headAng)*size, y+Math.sin(a-headAng)*size );
				g.endFill();
		}
	}


	public static function renderFields(fieldInstances:Array<data.inst.FieldInstance>, baseColor:dn.Col, ctx:FieldRenderContext, parent:h2d.Flow) {
		var allRenders = [];
		parent.removeChildren();

		var ei = switch ctx {
			case EntityCtx(g, ei, ld): ei;
			case LevelCtx(l): null;
		}

		switch settings.v.fieldsRender {
			case FR_Outline:
			case FR_Table:
				parent.verticalSpacing = M.round( 2 * settings.v.editorUiScale );
		}

		// Detect errors
		for(fi in fieldInstances)
			if( fi.hasAnyErrorInValues(ei) )
				baseColor = 0xff0000;

		// Create individual field renders
		for(fi in fieldInstances) {
			// Skip fields not displayed in world mode
			if( !fi.def.editorShowInWorld && Editor.ME.worldMode )
				continue;

			var fr = renderField(fi, baseColor, ctx);
			if( fr==null || fr.value.numChildren==0 )
				continue;

			allRenders.push(fr);
			var row = new h2d.Flow(parent);
			row.verticalAlign = Middle;
			row.setScale( settings.v.editorUiScale*fi.def.editorDisplayScale );
			if( fr.label.numChildren>0 ) {
				row.addChild(fr.label);
				row.addSpacing(6);
				row.paddingBottom = 2;
			}
			else
				row.horizontalAlign = Middle;
			row.addChild(fr.value);
		}

		parent.reflow();

		// Align labels
		var maxLabelWidth = 0.;
		var maxValueWidth = 0.;
		var anyLabel = false;
		for(fr in allRenders) {
			maxLabelWidth = M.fmax(maxLabelWidth, fr.label.outerWidth);

			// Value width is only included if the value is to be aligned
			if( settings.v.fieldsRender==FR_Table || fr.label.numChildren>0 )
				maxValueWidth = M.fmax(maxValueWidth, fr.value.outerWidth);

			if( fr.label.numChildren>0 )
				anyLabel = true;
		}
		for(fr in allRenders)
			if( fr.label.numChildren>0 ) {
				// Align label + value
				fr.label.minWidth = Std.int( maxLabelWidth );
				fr.value.minWidth = Std.int( maxValueWidth );
			}
			else if( anyLabel && settings.v.fieldsRender==FR_Table ) {
				// Align value only in table view
				fr.value.paddingLeft = M.round( maxLabelWidth + 2*settings.v.editorUiScale );
				fr.value.minWidth = Std.int( maxValueWidth );
			}


		switch settings.v.fieldsRender {
			case FR_Outline:

			case FR_Table:
				final padX = 4 * settings.v.editorUiScale;
				final padY = 2 * settings.v.editorUiScale;

				// Labels background
				if( anyLabel ) {
					var bg = new h2d.Bitmap( h2d.Tile.fromColor(baseColor.toBlack(0.85)) );
					parent.addChildAt(bg, 0);
					parent.getProperties(bg).isAbsolute = true;
					bg.setPosition(-padX, -padY+1);
					bg.scaleX = maxLabelWidth*settings.v.editorUiScale + padX*2;
					bg.scaleY = parent.outerHeight + padY*2;
				}

				// Fields background
				if( parent.numChildren>0 ) {
					var bg = new h2d.Bitmap( h2d.Tile.fromColor(baseColor.toBlack(0.65)) );
					parent.addChildAt(bg, 0);
					parent.getProperties(bg).isAbsolute = true;
					bg.setPosition(-padX + maxLabelWidth*settings.v.editorUiScale, -padY+1);
					bg.scaleX = parent.outerWidth - maxLabelWidth*settings.v.editorUiScale + padX*2;
					bg.scaleY = parent.outerHeight + padY*2;
				}
		}
	}


	public static function createBgFlow(flow:h2d.Flow, baseColor:dn.Col) {
		var padX = 2;
		var bg = new h2d.ScaleGrid( Assets.elements.getTile("fieldBg"), 2, 2, flow);
		bg.color.setColor( baseColor.toBlack(0.75).withAlphaIfMissing() );
		flow.addChildAt(bg, 0);
		flow.getProperties(bg).isAbsolute = true;
		bg.x = -padX;
		bg.y = 2;
		bg.width = flow.innerWidth + padX*2;
		bg.height = flow.innerHeight;
	}



	public static function createBgText(tf:h2d.Text, parent:h2d.Flow, baseColor:dn.Col) {
		var padX = 2;
		var bg = new h2d.ScaleGrid( Assets.elements.getTile("fieldBg"), 2, 2, parent);
		bg.color.setColor( baseColor.toBlack(0.75).withAlphaIfMissing() );
		parent.addChildAt(bg, 0);
		parent.getProperties(bg).isAbsolute = true;
		parent.reflow();
		bg.x = tf.x - padX;
		bg.y = tf.y+2;
		bg.width = tf.textWidth + padX*2;
		bg.height = tf.textHeight;
	}


	static inline function createText(target:h2d.Flow, col:dn.Col) {
		var tf = new h2d.Text(Assets.getRegularFont(), target);
		col.lightness = 1;
		tf.textColor = col;
		target.getProperties(tf).offsetY = M.round(-2*settings.v.editorUiScale); // compensate font base line
		return tf;
	}

	public static inline function createFilter(col:dn.Col) : Null<h2d.filter.Filter> {
		return switch settings.v.fieldsRender {
			case FR_Outline: new h2d.filter.Outline(1, col.toBlack(0.66), 0.6);
			case FR_Table: null;
		}
	}

	static function renderField(fi:data.inst.FieldInstance, baseColor:dn.Col, ctx:FieldRenderContext) : Null<RenderedField> {
		var fd = fi.def;
		if( fd.editorDisplayColor!=null )
			baseColor = fd.editorDisplayColor;

		var labelFlow = new h2d.Flow();
		labelFlow.verticalAlign = Middle;
		labelFlow.horizontalAlign = Right;
		labelFlow.padding = 0;
		switch ctx {
			case EntityCtx(g, ei, ld): labelFlow.filter = createFilter(baseColor);
			case LevelCtx(l): labelFlow.filter = createFilter(baseColor);
		}

		var valueFlow = new h2d.Flow();
		valueFlow.padding = 0;
		valueFlow.filter = labelFlow.filter;

		var ei = switch ctx {
			case EntityCtx(g, ei, ld): ei;
			case LevelCtx(l): null;
		}

		// Value error
		var err = fi.getFirstErrorInValues(ei);
		if( err!=null ) {
			if( fi.def.editorDisplayMode!=NameAndValue ) {
				var tf = createText(labelFlow, baseColor);
				tf.text = fd.identifier;
			}

			var tf = createText(valueFlow, 0xff4400);
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
				var tf = createText(labelFlow, baseColor.toWhite(0.3));
				tf.text = fd.identifier + ( settings.v.fieldsRender==FR_Outline ? " =" : "" );

				// Value
				valueFlow.addChild( FieldInstanceRender.renderValue(ctx, fi, C.toWhite(baseColor, 0.25)) );

			case ValueOnly:
				valueFlow.addChild( FieldInstanceRender.renderValue(ctx, fi, C.toWhite(baseColor, 0.25)) );

			case ArrayCountWithLabel:
				// Label
				var tf = createText(labelFlow, baseColor);
				tf.text = fd.identifier+":";

				// Value
				var tf = createText(valueFlow, baseColor);
				tf.text = '${fi.getArrayLength()} value(s)';

			case ArrayCountNoLabel:
				var tf = createText(valueFlow, baseColor);
				tf.text = '${fi.getArrayLength()} value(s)';

			case RadiusPx:
				switch ctx {
					case EntityCtx(g,_):
						g.lineStyle(2*zoomScale, baseColor, 0.33);
						g.drawCircle(0,0, fi.def.type==F_Float ? fi.getFloat(0) : fi.getInt(0));

					case LevelCtx(_):
				}

			case RadiusGrid:
				switch ctx {
					case EntityCtx(g, ei, ld):
						g.lineStyle(2*zoomScale, baseColor, 0.33);
						g.drawCircle(0,0, ( fi.def.type==F_Float ? fi.getFloat(0) : fi.getInt(0) ) * ld.gridSize);

					case LevelCtx(_):
				}

			case EntityTile:
			case LevelTile:

			case RefLinkBetweenCenters:
				switch ctx {
					case EntityCtx(g, ei, ld):
						var fx = ei.centerX - ei.x + ei._li.pxTotalOffsetX;
						var fy = ei.centerY - ei.y + ei._li.pxTotalOffsetY;
						for(i in 0...fi.getArrayLength()) {
							var tei = fi.getEntityRefInstance(i);
							if( tei==null )
								continue;
							var tx = M.round( tei.centerX + tei._li.level.worldX + tei._li.pxTotalOffsetX ) - ( ei.x + ei._li.level.worldX );
							var ty = M.round( tei.centerY + tei._li.level.worldY + tei._li.pxTotalOffsetY ) - ( ei.y + ei._li.level.worldY );
							renderRefLink(g, baseColor, fx,fy, tx,ty, 1, fi.def.editorLinkStyle, ei.isInSameSpaceAs(tei) ? Full : CutAtOrigin );
						}

					case LevelCtx(l):
				}

			case RefLinkBetweenPivots:
				switch ctx {
					case EntityCtx(g, ei, ld):
						var fx = ei.x - ei.x + ei._li.pxTotalOffsetX;
						var fy = ei.y - ei.y + ei._li.pxTotalOffsetY;
						for(i in 0...fi.getArrayLength()) {
							var tei = fi.getEntityRefInstance(i);
							if( tei==null )
								continue;
							var tx = M.round( tei.x + tei._li.level.worldX - ( ei.x + ei._li.level.worldX ) ) + tei._li.pxTotalOffsetX;
							var ty = M.round( tei.y + tei._li.level.worldY - ( ei.y + ei._li.level.worldY ) ) + tei._li.pxTotalOffsetY;
							renderRefLink(g, baseColor, fx,fy, tx,ty, 1, fi.def.editorLinkStyle, ei.isInSameSpaceAs(tei) ? Full : CutAtOrigin );
						}

					case LevelCtx(l):
				}


			case Points, PointStar, PointPath, PointPathLoop:
				switch ctx {
					case EntityCtx(g, ei, ld):
						var fx = ei.getPointOriginX(ld) - ei.x + ei._li.pxTotalOffsetX;
						var fy = ei.getPointOriginY(ld) - ei.y + ei._li.pxTotalOffsetY;
						var startX = fx;
						var startY = fy;

						for(i in 0...fi.getArrayLength()) {
							var pt = fi.getPointGrid(i);
							if( pt==null )
								continue;

							var tx = M.round( (pt.cx+0.5)*ld.gridSize - ei.x + ei._li.pxTotalOffsetX );
							var ty = M.round( (pt.cy+0.5)*ld.gridSize - ei.y + ei._li.pxTotalOffsetY );
							if( fd.editorDisplayMode!=Points )
								renderSimpleLink(g, baseColor, fx,fy, tx,ty, fi.def.editorLinkStyle);

							g.lineStyle(1*zoomScale, baseColor, 0.66);
							g.beginFill( C.toBlack(baseColor, 0.6) );
							final s = 4;
							g.moveTo(tx, ty-s);
							g.lineTo(tx+s, ty);
							g.lineTo(tx, ty+s);
							g.lineTo(tx-s, ty);
							g.lineTo(tx, ty-s);
							g.endFill();

							switch fd.editorDisplayMode {
								case Hidden, ValueOnly, NameAndValue, RadiusPx, RadiusGrid, ArrayCountNoLabel, ArrayCountWithLabel:
								case EntityTile:
								case LevelTile:
								case Points, PointStar:
								case RefLinkBetweenCenters:
								case RefLinkBetweenPivots:
								case PointPath, PointPathLoop:
									// Next point connects to this one
									fx = tx;
									fy = ty;
							}
						}

						// Loop to Entity
						if( fd.editorDisplayMode==PointPathLoop && fi.getArrayLength()>1 )
							renderSimpleLink(g, baseColor, fx,fy, startX, startY, fi.def.editorLinkStyle);

					case LevelCtx(_):
				}
		}

		return {
			label: labelFlow,
			value: valueFlow,
		};
	}



	static function renderValue(ctx:FieldRenderContext, fi:data.inst.FieldInstance, textColor:Int) : h2d.Flow {
		var valuesFlow = new h2d.Flow();
		valuesFlow.layout = Horizontal;
		valuesFlow.verticalAlign = Middle;

		var showArrayBrackets = fi.def.isArray;
		if( fi.def.isArray ) {
			var multiLinesArray = false;
			switch fi.def.type {
				case F_Int:
				case F_Float:
				case F_String: multiLinesArray = true; showArrayBrackets = false;
				case F_Text: multiLinesArray = true; showArrayBrackets = false;
				case F_Bool:
				case F_Color:
				case F_Enum(enumDefUid):
				case F_Point:
				case F_Path: multiLinesArray = true;
				case F_EntityRef: multiLinesArray = true; showArrayBrackets = false;
				case F_Tile:
			}
			if( multiLinesArray ) {
				valuesFlow.multiline = true;
				valuesFlow.maxWidth = MAX_TEXT_WIDTH;
				if( !showArrayBrackets ) {
					valuesFlow.verticalSpacing = 8;
					valuesFlow.layout = Vertical;
				}
			}
		}


		// Array opening
		if( showArrayBrackets && fi.def.isArray && fi.getArrayLength()>1 ) {
			// var tf = createText(valuesFlow, textColor);
			// tf.text = "[";
		}

		// Empty array with "always" display
		if( fi.def.isArray && fi.getArrayLength()==0 && fi.def.editorAlwaysShow ) {
			var tf = createText(valuesFlow, textColor);
			tf.text = "--empty--";
		}


		var iconSize = ( fi.getArrayLength()<=1 ? 24 : 16 ) * Editor.ME.camera.pixelRatio;
		for( idx in 0...fi.getArrayLength() ) {
			if( fi.def.editorAlwaysShow || !fi.valueIsNull(idx) ) {
				if( fi.hasIconForDisplay(idx) ) {
					// Icon
					var w = new h2d.Flow(valuesFlow);
					var tile = fi.getIconForDisplay(idx);
					var bmp = new h2d.Bitmap( tile, w );
					var s = M.fmin( iconSize/tile.width, iconSize/tile.height );
					bmp.setScale(s);
				}
				else if( fi.def.type==F_Color ) {
					// Color disc
					var g = new h2d.Graphics(valuesFlow);
					var r = iconSize*0.5;
					g.beginFill( fi.getColorAsInt(idx) );
					g.lineStyle(1, 0x0, 0.8);
					g.drawCircle(r,r,r, 16);
				}
				else {
					// Text render
					var tf = createText(valuesFlow, textColor);
					switch ctx {
						case EntityCtx(g, ei, ld):
							tf.maxWidth = MAX_TEXT_WIDTH;

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

					// Comma separator
					if( fi.def.isArray && idx<fi.getArrayLength()-1 )
						tf.text+=",";
				}
			}

			// Array separator
			if( showArrayBrackets && fi.def.isArray && idx<fi.getArrayLength()-1 ) {
				valuesFlow.addSpacing(2);
				// var tf = createText(valuesFlow, textColor);
				// tf.text = ",";
			}
		}

		// Array closing
		// if( showArrayBrackets && fi.def.isArray && fi.getArrayLength()>1 ) {
		// 	var tf = createText(valuesFlow, textColor);
		// 	tf.text = "]";
		// }

		return valuesFlow;
	}


}