package misc;

import sortablejs.*;
import sortablejs.Sortable;
import js.node.Fs;

typedef InternalSortableOptions = {
	var ?onlyDraggables: Bool;
	var ?disableAnim: Bool;
}

class JsTools {

	/**
		Use SortableJS to make some list sortable
		See: https://github.com/SortableJS/Sortable
	**/
	public static function makeSortable(jSortable:js.jquery.JQuery, ?jScrollRoot:js.jquery.JQuery, ?group:String, onSort:(event:SortableDragEvent)->Void, ?extraOptions:InternalSortableOptions) {
		if( extraOptions==null )
			extraOptions = {}

		if( jSortable.length!=1 )
			throw "Used sortable on a set of "+jSortable.length+" element(s)";

		jSortable.addClass("sortable");

		// Base settings
		var options : SortableOptions = {
			onStart: function(ev) {
				App.ME.jBody.addClass("sorting");
				jSortable.addClass("sorting");
				new J(ev.item).addClass("dragging");
			},
			onEnd: function(ev) {
				App.ME.jBody.removeClass("sorting");
				jSortable.removeClass("sorting");
				new J(ev.item).removeClass("dragging");
			},
			onSort: function(ev) {
				if( ev.oldIndex!=ev.newIndex || ev.from!=ev.to )
					onSort(ev);
				else
					new J(ev.item).click();
			},
			group: group,
			scroll: jScrollRoot!=null ? jScrollRoot.get(0) : jSortable.get(0),
			scrollSpeed: 40,
			scrollSensitivity: 140,
			animation: extraOptions.disableAnim==true ? 0 : 100,
		}

		// Custom handle
		if( jSortable.children().children(".sortHandle").length>0 ) {
			options.handle = ".sortHandle";
			jSortable.addClass("customHandle");
		}

		// Extra options
		if( extraOptions.onlyDraggables==true ) {
			jSortable.addClass("onlyDraggables");
			options.draggable = ".draggable";
		}

		Sortable.create( jSortable.get(0), options);
	}


	public static function createValuesSelect<T>(?jSelect:js.jquery.JQuery, cur:Null<T>, allValues:Array<T>, allowNull:Bool, ?def:T, ?printer:T->String, onSelect:T->Void) {
		if( jSelect==null )
			jSelect = new J('<select/>');
		else {
			jSelect.empty().off();
			jSelect.removeClass("isNull");
		}

		// Ensure cur is part of allValues
		if( !allValues.contains(cur) )
			cur = def;

		// "None" option
		if( allowNull ) {
			var jOpt = new J("<option/>");
			jSelect.prepend(jOpt);
			jOpt.text( printer==null ? Lang.t._("(none)") : printer(null) );
			jOpt.attr("value", "");
			if( cur==null ) {
				jSelect.addClass("isNull");
				jOpt.attr("selected","selected");
			}
		}

		// Values
		var i = 0;
		for(v in allValues) {
			var jOpt = new J('<option value="$i"/>');
			jSelect.append(jOpt);
			jOpt.text(printer!=null ? printer(v) : Std.string(v));

			if( def!=null && v==def )
				jOpt.append(" "+L.t._("(default)"));

			if( v==cur )
				jOpt.prop("selected",true);

			i++;
		}
		jSelect.change( (_)->{
			var i = Std.parseInt( jSelect.val() );
			onSelect(allValues[i]);
		});

		return jSelect;
	}


	/**
		Create a Tileset <select/>
	**/
	public static function createTilesetSelect(project:data.Project, ?jSelect:js.jquery.JQuery, curUid:Null<Int>, allowNull=false, ?nullLabel:String, onPick:Null<Int>->Void) {
		// Init select
		if( jSelect!=null ) {
			if( !jSelect.is("select") )
				throw "Need a <select> element!";
			jSelect.off().empty().show();
		}
		else
			jSelect = new J('<select/>');
		jSelect.removeClass("required");
		jSelect.removeClass("noValue");

		// Null value
		if( nullLabel==null )
			nullLabel = "Select a tileset";
		if( allowNull || curUid==null ) {
			var jOpt = new J('<option value="-1">-- $nullLabel --</option>');
			jOpt.appendTo(jSelect);
		}

		// Classes
		if( curUid!=null && project.defs.getTilesetDef(curUid)==null || !allowNull && curUid==null )
			jSelect.addClass("required");
		else if( curUid==null )
			jSelect.addClass("noValue");

		// Fill select
		appendTilesetsToSelect(project, jSelect);

		// Select current one
		var curTd = curUid==null ? null : project.defs.getTilesetDef(curUid);
		if( curTd!=null && curTd.isUsingEmbedAtlas() )
			jSelect.val( curTd.embedAtlas.getName() );
		else
			jSelect.val( curUid==null ? "-1" : Std.string(curUid) );

		// Change event
		jSelect.change( function(ev) {
			var tid : Null<Int> = Std.parseInt( jSelect.val() );
			if( jSelect.val()=="-1" )
				tid = null;
			else if( !M.isValidNumber(tid) ) {
				// Embed tileset
				var id = ldtk.Json.EmbedAtlas.createByName(jSelect.val());
				var td = project.defs.getEmbedTileset(id);
				tid = td.uid;
			}
			if( tid==curUid )
				return;

			onPick(tid);
		});

		return jSelect;
	}


	/**
		Create a Tileset <select/>
	**/
	public static function appendTilesetsToSelect(project:data.Project, jSelect:js.jquery.JQuery) {
		// List tilesets, grouped by tags
		var tagGroups = project.defs.groupUsingTags(project.defs.tilesets, td->td.tags);
		for( group in tagGroups ) {
			var jOptGroup = new J('<optgroup/>');
			jOptGroup.appendTo(jSelect);
			if( tagGroups.length<=1 )
				jOptGroup.attr("label","All tilesets");
			else
				jOptGroup.attr("label", group.tag==null ? L._Untagged() : group.tag);
			for(td in group.all ) {
				var jOpt = new J('<option value="${td.uid}"/>');
				jOpt.appendTo(jOptGroup);
				if( td.isUsingEmbedAtlas() ) {
					jOpt.attr("value", td.embedAtlas.getName());
					var inf = Lang.getEmbedAtlasInfos( td.embedAtlas );
					jOpt.text( inf.displayName );
				}
				else {
					jOpt.attr("value", Std.string(td.uid));
					jOpt.text( td.identifier );
				}
			}
		}

		// Unused embed tilesets
		var jOptGroup = new J('<optgroup label="Integrated LDtk tilesets"/>');
		for(k in ldtk.Json.EmbedAtlas.getConstructors()) {
			var id = ldtk.Json.EmbedAtlas.createByName(k);
			if( project.defs.isEmbedAtlasBeingUsed(id) )
				continue;

			var inf = Lang.getEmbedAtlasInfos(id);
			var jOpt = new J('<option value="$k"/>');
			jOpt.appendTo(jOptGroup);
			jOpt.text( inf.displayName );
		}
		if( jOptGroup.children().length>0 )
			jOptGroup.appendTo(jSelect);
	}


	public static function focusScrollableList(jList:js.jquery.JQuery, jElem:js.jquery.JQuery) {
		var targetY = jElem.position().top + jList.scrollTop();

		if( jList.css("position")=="static" )
			jList.css("position", "relative");

		targetY -= jList.outerHeight()*0.5;
		targetY = M.fclamp( targetY, 0, jList.prop("scrollHeight")-jList.outerHeight() );

		jList.scrollTop(targetY);
	}


	public static function createLayerTypeIcon2(type:ldtk.Json.LayerType) : js.jquery.JQuery {
		var icon = new J('<span class="icon"/>');
		icon.addClass( switch type {
			case IntGrid: "intGrid";
			case AutoLayer: "autoLayer";
			case Entities: "entity";
			case Tiles: "tile";
		});
		return icon;
	}

	public static function createLayerTypeIconAndName(type:ldtk.Json.LayerType) : js.jquery.JQuery {
		var wrapper = new J('<span class="layerType"/>');

		wrapper.append( createLayerTypeIcon2(type) );

		var name = new J('<span class="name"/>');
		name.appendTo(wrapper);
		name.text( L.getLayerType(type) );

		return wrapper;
	}

	public static function createFieldTypeIcon(type:ldtk.Json.FieldType, withName=true, ?ctx:js.jquery.JQuery) : js.jquery.JQuery {
		var icon = new J("<span/>");
		icon.addClass("icon fieldType");
		icon.addClass(type.getName());
		// icon.css({
			// backgroundColor: data.def.FieldDef.getTypeColorHex(type, 0.5),
			// borderColor: data.def.FieldDef.getTypeColorHex(type),
		// });
		if( withName )
			icon.append('<span class="typeName">'+L.getFieldType(type)+'</span>');
		icon.append('<span class="typeIcon">'+L.getFieldTypeShortName(type)+'</span>');

		if( ctx!=null )
			icon.appendTo(ctx);

		return icon;
	}


	public static function createEntityPreview(project:data.Project, ed:data.def.EntityDef, sizePx=32) {
		var jWrapper = new J('<div class="entityPreview icon"></div>');
		jWrapper.css("width", sizePx+"px");
		jWrapper.css("height", sizePx+"px");

		if( ed.uiTileRect!=null && ed.uiTileRect.w>0 ) {
			// Alt custom UI tile
			var td = project.defs.getTilesetDef(ed.uiTileRect.tilesetUid);
			if( td!=null ) {
				var jImg = td.createTileHtmlImageFromRect(ed.uiTileRect);
				jWrapper.append(jImg);
			}
		}
		else if( ed.renderMode==Tile && ed.tileRect!=null ) {
			// Tile
			var td = project.defs.getTilesetDef(ed.tileRect.tilesetUid);
			if( td!=null ) {
				var jImg = td.createTileHtmlImageFromRect(ed.tileRect);
				jWrapper.append(jImg);
				jImg.css("opacity", ed.tileOpacity);
			}
			if( ed.lineOpacity>0 ) {
				jWrapper.addClass("hasBg");
				jWrapper.css("outline", "1px solid "+new dn.Col(ed.color).toCssRgba(ed.lineOpacity));
			}
			if( ed.fillOpacity>0 ) {
				jWrapper.addClass("hasBg");
				jWrapper.css("background-color", new dn.Col(ed.color).toCssRgba(ed.fillOpacity));
			}
		}
		else {
			// Shape
			var superScale = 3;
			var scaledSizePx = sizePx * superScale;
			var padPct = 0.05;
			var pad = M.round( scaledSizePx*padPct );
			var shapeWid = scaledSizePx * (1-padPct*2) * ( ed.width>ed.height ? 1 : ed.width/ed.height );
			var shapeHei = scaledSizePx * (1-padPct*2) * ( ed.height>ed.width ? 1 : ed.height/ed.width );
			var jCanvas = new J('<canvas></canvas>');
			jCanvas.appendTo(jWrapper);
			jCanvas.attr("width", scaledSizePx);
			jCanvas.attr("height", scaledSizePx);

			var cnv = Std.downcast( jCanvas.get(0), js.html.CanvasElement );
			var ctx = cnv.getContext2d();

			ctx.fillStyle = new dn.Col(ed.color).toCssRgba(ed.fillOpacity);
			ctx.strokeStyle = new dn.Col(ed.color).toCssRgba(ed.lineOpacity);
			ctx.lineWidth = 2/superScale;

			switch ed.renderMode {
				case Rectangle:
					ctx.fillRect(scaledSizePx*0.5-shapeWid*0.5, scaledSizePx*0.5-shapeHei*0.5, shapeWid, shapeHei);
					ctx.strokeRect(scaledSizePx*0.5-shapeWid*0.5, scaledSizePx*0.5-shapeHei*0.5, shapeWid, shapeHei);

				case Ellipse:
					ctx.beginPath();
					ctx.ellipse(
						scaledSizePx*0.5, scaledSizePx*0.5,
						shapeWid*0.5, shapeHei*0.5,
						0, 0, M.PI*2
					);
					ctx.fill();
					ctx.stroke();

				case Cross:
					ctx.lineWidth = 3;
					ctx.moveTo(scaledSizePx*0.5-shapeWid*0.5, scaledSizePx*0.5-shapeHei*0.5);
					ctx.lineTo(scaledSizePx*0.5+shapeWid*0.5, scaledSizePx*0.5+shapeHei*0.5);
					ctx.moveTo(scaledSizePx*0.5+shapeWid*0.5, scaledSizePx*0.5-shapeHei*0.5);
					ctx.lineTo(scaledSizePx*0.5-shapeWid*0.5, scaledSizePx*0.5+shapeHei*0.5);
					ctx.stroke();

				case Tile: // N/A
			}
		}

		// var scale = sizePx / M.fmax(ed.width, ed.height);

		// var jCanvas = new J('<canvas></canvas>');
		// jCanvas.appendTo(jWrapper);
		// jCanvas.attr("width", ed.width*scale);
		// jCanvas.attr("height", ed.height*scale);

		// var cnv = Std.downcast( jCanvas.get(0), js.html.CanvasElement );
		// var ctx = cnv.getContext2d();

		// if( ed.uiTileRect!=null && ed.uiTileRect.w>0 ) {
		// 	// Custom override UI tile
		// 	var td = project.defs.getTilesetDef(ed.uiTileRect.tilesetUid);
		// 	ctx.fillStyle = C.intToHex(ed.color)+"88";
		// 	ctx.beginPath();
		// 	ctx.rect(0, 0, Std.int(ed.width*scale), Std.int(ed.height*scale));
		// 	ctx.fill();
		// 	var s = M.fmin(scale * ed.width/td.tileGridSize, scale * ed.height/td.tileGridSize);
		// 	td.drawTileRectToCanvas(jCanvas, ed.uiTileRect, 0,0, s,s);
		// }
		// else {
		// 	// Default editor visual
		// 	switch ed.renderMode {
		// 		case Rectangle:

		// 		case Cross:

		// 		case Ellipse:

		// 		case Tile:
		// 			ctx.fillStyle = C.intToHex(ed.color)+"66";
		// 			ctx.beginPath();
		// 			ctx.rect(0, 0, Std.int(ed.width*scale), Std.int(ed.height*scale));
		// 			ctx.fill();

		// 			if( ed.isTileDefined() ) {
		// 				var td = project.defs.getTilesetDef(ed.tilesetId);
		// 				var x = 0;
		// 				var y = 0;
		// 				var scaleX = 1.;
		// 				var scaleY = 1.;
		// 				switch ed.tileRenderMode {
		// 					case Stretch:
		// 						scaleX = scale * ed.width / td.tileGridSize;
		// 						scaleY = scale * ed.height / td.tileGridSize;

		// 					case FitInside:
		// 						var s = M.fmin(scale * ed.width / td.tileGridSize, scale * ed.height / td.tileGridSize);
		// 						scaleX = s;
		// 						scaleY = s;

		// 					case Cover, Repeat:
		// 						var s = M.fmin(scale * ed.width / td.tileGridSize, scale * ed.height / td.tileGridSize);
		// 						scaleX = s;
		// 						scaleY = s;

		// 					case FullSizeCropped:
		// 					case FullSizeUncropped:

		// 					case NineSlice:
		// 						scaleX = scale * ed.width / td.tileGridSize; // TODO
		// 						scaleY = scale * ed.height / td.tileGridSize;
		// 				}
		// 				td.drawTileRectToCanvas(jCanvas, ed.tileRect, x,y, scaleX, scaleY);
		// 			}
		// 	}
		// }


		return jWrapper;
	}


	public static function createPivotEditor( curPivotX:Float, curPivotY:Float, ?bgColor:dn.Col, allowAdvanced=false, ?width:Int, ?height:Int, onPivotChange:(pivotX:Float, pivotY:Float)->Void ) {
		var jPivots = new J( getHtmlTemplate("pivotEditor") );


		// Init grid
		var jGrid = jPivots.find(".grid");
		jGrid.find("input[type=radio]").attr("name", "pivot");

		if( bgColor!=null )
			jGrid.find(".bg").css( "background-color", C.intToHex(bgColor) );
		else
			jGrid.find(".bg").hide();

		jGrid.find("input[type=radio][value='"+curPivotX+" "+curPivotY+"']").prop("checked",true);

		jGrid.find("input[type=radio]").each( function(idx:Int, elem) {
			var r = new J(elem);
			r.change( function(ev) {
				var rawPivots = r.val().split(" ");
				onPivotChange( Std.parseFloat( rawPivots[0] ), Std.parseFloat( rawPivots[1] ) );
			});
		});

		// Advanced link
		var jAdvLink = jPivots.find("a.show");
		if( allowAdvanced )
			jAdvLink.click( (ev:js.jquery.Event)->{
				ev.preventDefault();
				jPivots.addClass("showAdvanced");
			});
		else
			jAdvLink.hide();

		// Auto open advanced panel
		var xr = curPivotX;
		var yr = curPivotY;
		if( allowAdvanced && ( xr!=0 && xr!=0.5 && xr!=1 || yr!=0 && yr!=0.5 && yr!=1 ) )
			jAdvLink.click();

		// Advanced form
		if( allowAdvanced ) {
			var jAdvanced = jPivots.find(".advanced .options");

			// X float
			var i = Input.linkToHtmlInput(xr, jAdvanced.find('[name="customFloatX"]'));
			i.setBounds(-50,50);
			i.onValueChange = (v)->onPivotChange(v, yr);

			// Y float
			var i = Input.linkToHtmlInput(yr, jAdvanced.find('[name="customFloatY"]'));
			i.setBounds(-50,50);
			i.onValueChange = (v)->onPivotChange(xr, v);

			var pixelX = M.floor( xr*width );
			var pixelY = M.floor( yr*height );

			// X pixels
			var i = Input.linkToHtmlInput(pixelX, jAdvanced.find('[name="customPixelX"]'));
			i.setBounds(-2048,2048);
			i.onValueChange = (v)->onPivotChange(v/width, yr);

			// Y pixels
			var i = Input.linkToHtmlInput(pixelY, jAdvanced.find('[name="customPixelY"]'));
			i.setBounds(-2048,2048);
			i.onValueChange = (v)->onPivotChange(xr, v/height);
		}

		return jPivots;
	}

	public static function createIcon(id:String) {
		var jIcon = new J('<span class="icon"/>');
		jIcon.addClass(id);
		return jIcon;
	}




	static var _fileCache : Map<String,String> = new Map();
	public static function clearFileCache(?name:String) {
		if( name==null )
			_fileCache = new Map();
		else if( _fileCache.exists(name) )
			_fileCache.remove(name);
	}

	public static function getHtmlTemplate(name:String, ?vars:Dynamic, useCache=true) : Null<String> {
		#if debug
		useCache = false;
		#end
		if( !useCache || !_fileCache.exists(name) ) {
			if( _fileCache.exists(name) )
				_fileCache.remove(name);
			App.LOG.fileOp("Loading HTML template "+name);
			var path = dn.FilePath.fromFile(App.APP_ASSETS_DIR + "tpl/" + name);
			path.extension = "html";

			if( !NT.fileExists(path.full) )
				throw "File not found "+path.full;

			_fileCache.set( name, NT.readFileString(path.full) );
		}
		else
			App.LOG.fileOp("Reading HTML template "+name+" from cache");

		var raw = _fileCache.get(name);
		if( vars!=null ) {
			for(k in Reflect.fields(vars))
				raw = StringTools.replace( raw, '::$k::', Reflect.field(vars,k) );
		}

		return raw;
	}


	static function getTmpFileInput() {
		var input = new J("input#tmpFileInput");
		if( input.length==0 ) {
			input = new J("<input/>");
			input.attr("type","file");
			input.attr("id","tmpFileInput");
			input.appendTo( App.ME.jBody );
			input.hide();
		}
		input.off();
		input.removeAttr("accept");
		input.removeAttr("nwsaveas");

		input.click( function(ev) {
			input.val("");
		});

		return input;
	}


	public static inline function createKeyInLabel(label:String) {
		var r = ~/(.*)\[(.*)\](.*)/gi;
		if( !r.match(label) )
			return new J('<span>$label</span>');
		else {
			var j = new J("<span/>");
			j.append(r.matched(1));
			j.append( new J('<span class="key">'+r.matched(2)+'</span>') );
			j.append(r.matched(3));
			return j;
		}
	}

	public static inline function createKey(?kid:Int, ?keyLabel:String) {
		if( kid!=null )
			keyLabel = K.getKeyName(kid);

		if( keyLabel.toLowerCase()=="shift" )
			keyLabel = "⇧";
		else if ( App.isMac() && keyLabel.toLowerCase()=="ctrl")
			keyLabel = "⌘";

		keyLabel = switch kid {
			case K.QWERTY_TILDE: "~";
			case 222: "²";
			case _: keyLabel;
		}

		return new J('<span class="key">$keyLabel</span>');
	}

	public static function parseKeysIn(jTarget:js.jquery.JQuery) {
		var funcKeyReg = ~/^f[0-9]{1,2}$/gi;

		var content = jTarget.contents();
		var jReplace = new J("<div/>");

		content.each( (idx,e)->{
			var j = new J(e);

			switch e.nodeType {

				// Parse a text to create "keys"
				case js.html.Node.TEXT_NODE:
					for(k in e.textContent.split(" ")) {
						if( k==null || k.length==0 )
							continue;

						jReplace.append( switch k.toLowerCase() {
							case "mouseleft": new J('<span class="icon mouseleft" title="Left mouse button"></span>');
							case "mouseright": new J('<span class="icon mouseright" title="Right mouse button"></span>');
							case "mousewheel": new J('<span class="icon mousewheel" title="Mouse wheel"></span>');
							case "mousemiddle": new J('<span class="icon mousemiddle" title="Middle mouse button"></span>');
							case "add": new J('<span class="key" title="Numeric pad +">+</span>');
							case "sub": new J('<span class="key" title="Numeric pad -">-</span>');

							case "+", "-", "to", "/", "or", '"', "'", "on": new J('<span class="misc">$k</span>');
							case "~": new J('<span class="key">${ App.ME.settings.v.navigationKeys==Zqsd ? "²" : "~" }</span>');

							case k.charAt(0) => "(": new J("<span/>").append(k);
							case k.charAt(k.length-1) => ")": new J("<span/>").append(k);

							case _:
								var keyName = switch k {
									case "macctrl": "ctrl";
									case _: k.toUpperCase();
								}
								var jKey = new J('<span class="key">$keyName</span>');
								switch k.toLowerCase() {
									case "shift", "alt" : jKey.addClass( k.toLowerCase() );
									case "macctrl" : jKey.addClass( App.isMac() ? "ctrl" : "??" );
									case "ctrl" : jKey.addClass( App.isMac() ? 'meta' : "ctrl" );
									case "delete", "escape": jKey.addClass("special");
									case _ if(funcKeyReg.match(k)): jKey.addClass("special");
									case _:
								}
								jKey;
						});
					}

				case _:
					// Keep other DOM elements as-is
					jReplace.append(j);
			}
		});

		return jReplace.contents();
	}


	public static function parseComponents(jCtx:js.jquery.JQuery) : Void {
		// Disable img dragging
		jCtx.find("img").attr("draggable","false");

		// Info bubbles: (i) and (!)
		jCtx.find(".info, info, warning").each( function(idx, e) {
			var jThis = new J(e);
			var isInfo = jThis.is("info, .info");

			if( jThis.data("str")==null ) {
				if( jThis.hasClass("identifier") ) {
					var extra = jThis.text();
					jThis.data(
						"str",
						L.t._("An identifier should be UNIQUE (in this context) and can only contain LETTERS, NUMBERS or UNDERSCORES (ie. \"_\").")
						+ (extra==null || extra.length==0 ? "" : "\n"+extra )
					);
				}
				else if( jThis.hasClass("userDoc") ) {
					var extra = jThis.text();
					jThis.data(
						"str",
						L.t._("User defined documentation that will appear near this element to provide help and tips to the level designers.")
						+ (extra==null || extra.length==0 ? "" : "\n"+extra )
					);
				}
				else
					jThis.data("str", jThis.text());
				jThis.empty();
			}
			ui.Tip.attach(jThis, jThis.data("str"), "infoTip");

			if( isInfo && jThis.parent("dt")!=null ) {
				jThis.mouseover( _->{
					jThis.parent().addClass("infoHighlight").next("dd").addClass("infoHighlight");
				});
				jThis.mouseout( _->{
					jThis.parent().removeClass("infoHighlight").next("dd").removeClass("infoHighlight");
				});
			}
		});

		// External links
		var links = jCtx.find("a[href^=http], button[href]");
		links.each( function(idx,e) {
			var link = new J(e);
			var url = link.attr("href");
			if( url=="#" )
				return;

			var cleanUrlReg = ~/(http[s]*:\/\/)*(.*)/g;
			cleanUrlReg.match(url);
			var displayUrl = cleanUrlReg.matched(2);
			var cut = 40;
			if( displayUrl.length>cut )
				displayUrl = displayUrl.substr(0,cut)+"...";

			if( link.attr("title")==null && link.attr("noTitle")==null )
				ui.Tip.attach(link, displayUrl, "link", true);

			link.click( function(ev:js.jquery.Event) {
				ev.preventDefault();
				ev.stopPropagation();
				electron.Shell.openExternal(url);
				N.msg("Opening url...");
			});
			link.on("auxclick", (ev:js.jquery.Event)->{
				switch ev.button {
					case 1:
						ev.preventDefault();
						electron.Shell.openExternal(url);

					case 2:
						var ctx = new ui.modal.ContextMenu(ev);
						ctx.addAction({
							label: L.t._("Copy URL"),
							cb: ()->{
								App.ME.clipboard.copyStr(url);
								N.copied();
							}
						});

					case _:
				}
			});
		});


		// Auto tool-tips
		jCtx.find("[title]:not([noTip]), [data-title]").each( function(idx,e) {
			var jThis = new J(e);
			if( jThis.attr("title")!=null ) {
				var str =  jThis.attr("title");
				jThis.removeAttr("title");
				jThis.attr("data-title", str);
			}
			var tipStr = jThis.attr("data-title");

			// Parse key shortcut
			var keys = [];
			if( jThis.attr("keys")!=null ) {
				var rawKeys = jThis.attr("keys").split("+").map( function(k) return StringTools.trim(k).toLowerCase() );
				for(k in rawKeys) {
					switch k {
						case "ctrl" : keys.push(K.CTRL);
						case "shift" : keys.push(K.SHIFT);
						case "alt" : keys.push(K.ALT);
						case "~": App.ME.settings.v.navigationKeys==Zqsd ? keys.push(222) : keys.push(K.QWERTY_TILDE);
						case _ :
							var funcReg = ~/[fF]([0-9]+)/;
							if( k.length==1 ) {
								var cid = k.charCodeAt(0);
								if( cid>="a".code && cid<="z".code )
									keys.push( cid - "a".code + K.A );
							}
							else if( funcReg.match(k) )
								keys.push( K.F1 + Std.parseInt(funcReg.matched(1)) - 1 );
					}
				}
			}

			ui.Tip.attach( jThis, tipStr, keys );
		});

		// Tabs
		jCtx.find("ul.tabs").each( function(idx,e) {
			var jTabs = new J(e);
			jTabs.find("li").click( function(ev:js.jquery.Event) {
				var jTab = ev.getThis();
				jTabs.find("li").removeClass("active");
				jTab.addClass("active");
				jTabs
					.siblings(".tab").hide()
					.filter("[section="+jTab.attr("section")+"]").show();
			});
			jTabs.find("li:first").click();
		});

		// Color pickers
		jCtx.find("input[type=color]").each( function(idx,e) {
			var jInput = new J(e);
			jInput
				.off(".picker")
				.on("click.picker", (ev:js.jquery.Event)->{
					ev.stopPropagation();
					ev.preventDefault();
					var colorTag = jInput.attr("colorTag");
					if( colorTag!=null )
						new ui.modal.dialog.ColorPicker( colorTag, jInput );
					else
						new ui.modal.dialog.ColorPicker( Const.getNicePalette(), jInput );
				});
		});


		// Collapser
		jCtx.find(".collapser:visible").each( (idx,e)->{
			var jCollapser = new J(e);
			var tid = jCollapser.attr("target");
			var jTarget = tid!=null ? App.ME.jBody.find("#"+tid) : jCollapser.next();

			var uiStateId : Null<Settings.UiState> = cast jCollapser.attr("id"); // might be null

			// Init default, if any
			var customDefault : Null<Bool> = null;
			if( jCollapser.attr("default")!=null ) {
				customDefault = switch jCollapser.attr("default").toLowerCase() {
					case "true", "open", "expand", "1": true;
					case _: false;
				}
			}
			if( uiStateId!=null && !App.ME.settings.hasUiState(uiStateId) ) {
				if( customDefault!=null )
					App.ME.settings.setUiStateBool(uiStateId, customDefault);
				else
					App.ME.settings.setUiStateBool(uiStateId, false);
			}

			if( uiStateId!=null ) {
				// Init from memory
				if( App.ME.settings.getUiStateBool(uiStateId)==true ) {
					jTarget.show();
					parseComponents(jTarget);
					jCollapser.addClass("expanded");
				}
				else {
					jTarget.hide();
					jCollapser.addClass("collapsed");

				}
			}
			else if( customDefault==true ) {
				// Use provided default
				jTarget.show();
				parseComponents(jTarget);
				jCollapser.addClass("expanded");
			}
			else {
				// Closed by default
				jTarget.hide();
				jCollapser.addClass("collapsed");
			}


			jCollapser
				.off(".collapser")
				.on("click.collapser", _->{
					var expanded = jTarget.is(":visible");
					jCollapser.removeClass("collapsed");
					jCollapser.removeClass("expanded");
					if( uiStateId!=null )
						App.ME.settings.setUiStateBool(uiStateId, !expanded);

					if( expanded ) {
						jCollapser.addClass("collapsed");
						jTarget.slideUp(50, ()->dn.Process.resizeAll(false));
					}
					else {
						jCollapser.addClass("expanded");
						jTarget.slideDown(30, ()->dn.Process.resizeAll(false));
						jTarget.show();
						parseComponents(jTarget);
						dn.Process.resizeAll(false);
					}
				});
		});

		// Advanced Selects
		jCtx.find(".advancedSelect").remove();
		jCtx.find("select.advanced:visible").each( (idx,e)->{
			var jOldSelect = new J(e);

			// Create advanced select & options
			var jSelect = new J('<div class="advancedSelect"/>');
			var classes = try (~/\s/).split( jOldSelect.attr("class") ) catch(_) [];
			for(c in classes)
				if( c!="advanced" )
					jSelect.addClass(c);
			jSelect.insertBefore(jOldSelect);
			jSelect.append('<span class="expand icon expanded"></span>');
			var hasImages = jOldSelect.find("[tile]").length>0;
			for(elem in jOldSelect.children("option")) {
				var jOldOpt = new J(elem);
				var jOpt = new J('<div class="option"/>');
				jSelect.append(jOpt);
				jOpt.attr("value", jOldOpt.attr("value"));
				jOpt.text( jOldOpt.text() );
				if( jOldOpt.hasClass("default") )
					jOpt.addClass("default");

				if( jOldOpt.prop("disabled")==true )
					jOpt.addClass("disabled");

				// Background color
				if( jOldOpt.is("[color]") ) {
					var c = dn.Col.parseHex( jOldOpt.attr("color") );
					jOpt.css("background-color", c.toCssRgba(0.3));
				}

				// Selected value
				if( jOldSelect.val()==jOldOpt.attr("value") )
					jOpt.addClass("selected");

				// Icon
				if( jOldOpt.attr("tile")!=null ) {
					var r : ldtk.Json.TilesetRect = haxe.Json.parse(jOldOpt.attr("tile"));
					var td = try Editor.ME.project.defs.getTilesetDef(r.tilesetUid) catch(_) null;
					if( td!=null ) {
						var img = td.getTileHtmlImg(r);
						jOpt.prepend(img);
					}
				}
				else if( hasImages )
					jOpt.prepend('<div class="placeholder"></div>');
			}

			// Open select
			jSelect.click(_->{
				var uiStateId : Null<Settings.UiState> = cast jOldSelect.attr("id");
				new ui.modal.dialog.SelectPicker(jSelect, uiStateId, v->{
					jOldSelect.val(v).change();
				});
			});
		});
	}


	public static function makePath(path:String, ?pathColor:UInt, highlightFirst=false) {
		path = StringTools.replace(path,"\\","/");
		var parts = path.split("/");
		var i = 0;
		parts = parts.map( function(p) {
			var col = pathColor==null ? C.fromStringLight(p) : pathColor;
			if( (i++)==0 && highlightFirst && parts.length>1 )
				return '<span style="background-color:${C.intToHex(C.toBlack(col,0.3))}" class="highlight">$p</span>';
			else
				return '<span style="color:${C.intToHex(col)}">$p</span>';
		});
		var e = new J( parts.join('<span class="slash">/</span>') );
		return e.wrapAll('<div class="path"/>').parent();
	}


	// *** File API (node) **************************************

	public static function removeDirFiles(path:String, ?onlyExts:Array<String>) {
		if( !NT.fileExists(path) )
			return;

		if( !NT.isDirectory(path) )
			return;

		var extMap = new Map();
		if( onlyExts!=null )
			for(e in onlyExts)
				extMap.set(e, true);


		App.LOG.fileOp("Emptying dir "+path+" (onlyExts="+onlyExts+")...");
		js.node.Require.require("fs");
		var fp = dn.FilePath.fromDir(path);
		for(f in NT.readDir(path)) {
			fp.fileWithExt = f;
			if( js.node.Fs.lstatSync(fp.full).isFile() && ( onlyExts==null || extMap.exists(fp.extension) ) )
				js.node.Fs.unlinkSync(fp.full);
		}
	}

	public static function findFilesRec(dirPath:String, ?ext:String) : Array<dn.FilePath> {
		dirPath = dn.FilePath.cleanUp(dirPath, false);

		if( !NT.fileExists(dirPath) )
			return [];

		var all = [];
		var pendings = [dirPath];
		while( pendings.length>0 ) {
			var dir = pendings.shift();
			for(f in NT.readDir(dir)) {
				var fp = dn.FilePath.fromFile(dir+"/"+f);
				if( js.node.Fs.lstatSync(fp.full).isFile() ) {
					if( ext==null || fp.extension==ext )
						all.push(fp);
				}
				else if( !js.node.Fs.lstatSync(fp.full).isSymbolicLink() )
					pendings.push(fp.full);
			}
		}
		return all;
	}

	public static function getLogPath() {
		#if debug
		return dn.FilePath.fromDir( ET.getAppResourceDir()+"/ldtk.log" ).useSlashes().full;
		#else
		return dn.FilePath.fromDir( ET.getLogDir()+"/ldtk.log" ).useSlashes().full;
		#end
	}

	/** Path to LDtk exe **/
	public static function getExeDir() {
		#if debug
		var path = ET.getAppResourceDir()+"/foo.exe";
		#else
		var path = ET.getExeDir();
		#end
		return dn.FilePath.fromFile( path ).useSlashes().directory;
	}

	/** Return path to the embed "assets" dir **/
	public static function getAssetsDir() {
		return dn.FilePath.fromDir( ET.getAppResourceDir()+"/assets" ).useSlashes().directory;
	}

	/** Return path to the "extraFiles" dir, stored as-is in the LDtk install dir **/
	public static function getExtraFilesDir(?subDir:String) {
		var fp = dn.FilePath.fromDir( getExeDir() );
		fp.useSlashes();
		if( fp.getLastDirectory()=="MacOS" )
			fp.removeLastDirectory();
		fp.appendDirectory("extraFiles");
		if( subDir!=null && subDir.length>0 )
			fp.appendDirectory(subDir);
		return fp.full;
	}

	public static function getSamplesDir() {
		return getExtraFilesDir("samples");
	}

	public static function locateFile(path:String, isFile:Bool) {
		if( path==null )
			N.error("No file");
		else {
			if( !NT.fileExists(path) ) {
				if( isFile )
					path = dn.FilePath.extractDirectoryWithoutSlash(path, true);

				if( !isFile || !NT.fileExists(path) )
					N.error("Sorry, but this file couldn't be found.");
				else {
					N.msg("Locating file...");
					ET.locate(path, false);
				}
			}
			else {
				N.msg("Locating file...");
				ET.locate(path, isFile);
			}
		}
	}

	public static function makeLocateLink(filePath:Null<String>, isFile:Bool) {
		var a = new J('<a class="exploreTo"/>');
		a.append('<span class="icon"/>');
		a.find(".icon").addClass("locate");
		a.click( function(ev) {
			ev.preventDefault();
			ev.stopPropagation();
			locateFile(filePath, isFile);
		});

		if( filePath==null )
			a.hide();

		ui.Tip.attach( a, isFile ? L.t._("Locate file") : L.t._("Locate folder") );

		return a;
	}


	public static function isWindows() {
		return js.Node.process.platform.toLowerCase().indexOf("win")==0;
	}

	public static function removeClassReg(jElem:js.jquery.JQuery, reg:EReg) {
		jElem.removeClass( function(idx, classes) {
			var all = [];
			while( reg.match(classes) ) {
				all.push( reg.matched(0) );
				classes = reg.matchedRight();
			}
			return all.join(" ");
		});
	}

	public static function clearCanvas(jCanvas:js.jquery.JQuery) {
		if( !jCanvas.is("canvas") )
			throw "Not a canvas";

		var cnv = Std.downcast( jCanvas.get(0), js.html.CanvasElement );
		cnv.getContext2d().clearRect(0,0, cnv.width, cnv.height);
	}


	public static function createTilePicker(
		tilesetId: Null<Int>,
		selectMode: TilesetSelectionMode=MultipleIndividuals,
		tileIds: Array<Int>,
		useSavedSelections=true,
		onPick: (tileIds:Array<Int>)->Void
	) {
		var jTileCanvas = new J('<canvas class="tile"></canvas>');

		if( tilesetId!=null ) {
			jTileCanvas.addClass("active");
			var td = Editor.ME.project.defs.getTilesetDef(tilesetId);
			var isRectMode = switch selectMode {
				case None: false;
				case MultipleIndividuals: false;
				case OneTile, OneTileAndClose: false;
				case TileRect, TileRectAndClose: true;
			}

			if( tileIds.length==0 ) {
				// No tile selected
				jTileCanvas.addClass("empty");
			}
			else if( !isRectMode ) {
				// Single/random tiles
				jTileCanvas.removeClass("empty");
				jTileCanvas.attr("width", td.tileGridSize);
				jTileCanvas.attr("height", td.tileGridSize);
				td.drawTileToCanvas(jTileCanvas, tileIds[0]);
				if( tileIds.length>1 && !isRectMode ) {
					// Cycling animation among multiple tiles
					jTileCanvas.addClass("multi");
					var idx = 0;
					Editor.ME.createChildProcess(function(p) {
						if( p.cd.hasSetS("tick",0.2) )
							return;

						if( jTileCanvas.parents("body").length==0 ) {
							p.destroy();
							return;
						}

						idx++;
						if( idx>=tileIds.length )
							idx = 0;

						clearCanvas(jTileCanvas);
						td.drawTileToCanvas(jTileCanvas, tileIds[idx]);
					});
				}
			}
			else {
				// Tile group stamp
				var bounds = td.getTileGroupBounds(tileIds);
				var wid = M.imax(bounds.wid, 1);
				var hei = M.imax(bounds.hei, 1);
				jTileCanvas.attr("width", td.tileGridSize * wid );
				jTileCanvas.attr("height", td.tileGridSize * hei );
				var scale = M.fmin(1, 48 / ( M.fmax(wid, hei)*td.tileGridSize ) );
				jTileCanvas.css("width", td.tileGridSize * wid * scale );
				jTileCanvas.css("height", td.tileGridSize * hei * scale );

				for(tid in tileIds) {
					var tcx = td.getTileCx(tid);
					var tcy = td.getTileCy(tid);
					td.drawTileToCanvas(jTileCanvas, tid, (tcx-bounds.left)*td.tileGridSize, (tcy-bounds.top)*td.tileGridSize);
				}
			}

			// Open picker
			jTileCanvas.click( function(ev) {
				openTilePickerModal(td.uid, selectMode, tileIds, false, onPick);
			});
		}
		else {
			// Invalid tileset
			jTileCanvas.addClass("empty");
		}

		return jTileCanvas;
	}


	public static function openTilePickerModal(
		tilesetId: Null<Int>,
		selectMode: TilesetSelectionMode,
		tileIds: Array<Int>,
		useSavedSelections=true,
		onPick: (tileIds:Array<Int>)->Void
	) {
		var td = Editor.ME.project.defs.getTilesetDef(tilesetId);
		if( td==null ) {
			N.error("No valid tileset");
			return false;
		}

		var m = new ui.Modal();
		m.addClass("singleTilePicker");

		var tp = new ui.Tileset(m.jContent, td, selectMode);
		tp.useSavedSelections = useSavedSelections;
		tp.setSelectedTileIds(tileIds);
		tp.onClickOutOfBounds = m.close;
		tp.onSelectAnything = ()->{
			switch selectMode {
				case None:
				case MultipleIndividuals:
				case OneTile:
				case TileRect:

				case OneTileAndClose:
					onPick([ tp.getSelectedTileIds()[0] ]);
					m.close();

				case TileRectAndClose:
					onPick( tp.getSelectedTileIds() );
					m.close();
			}
		}
		m.onCloseCb = function() {
			switch selectMode {
				case None:
				case OneTileAndClose:
				case TileRectAndClose:

				case OneTile:
					onPick([ tp.getSelectedTileIds()[0] ]);

				case MultipleIndividuals:
					onPick( tp.getSelectedTileIds() );

				case TileRect:
					onPick( tp.getSelectedTileIds() );
			}
		}
		tp.focusOnSelection(true);

		return true;
	}



	public static function createTileRectPicker(
		tilesetId: Null<Int>,
		cur: Null<ldtk.Json.TilesetRect>,
		active=true,
		onPick: (Null<ldtk.Json.TilesetRect>)->Void
	) {
		var jTileCanvas = new J('<canvas class="tile"></canvas>');

		if( tilesetId!=null ) {
			var td = Editor.ME.project.defs.getTilesetDef(tilesetId);
			if( td==null )
				jTileCanvas.addClass("empty");
			else {
				if( active )
					jTileCanvas.addClass("active");

				if( cur==null ) {
					// No tile selected
					jTileCanvas.addClass("empty");
				}
				else {
					// Tile rect
					jTileCanvas.attr("width", cur.w);
					jTileCanvas.attr("height", cur.h);
					var scale = 35 / M.fmax(cur.w, cur.h);
					jTileCanvas.css("width", cur.w * scale );
					jTileCanvas.css("height", cur.h * scale );
					td.drawTileRectToCanvas(jTileCanvas, cur);
				}
				ui.Tip.attach(jTileCanvas, "Use LEFT click to pick a tile or RIGHT click to remove it.");

				// Open picker
				if( active )
					jTileCanvas.mousedown( (ev:js.jquery.Event)->{
						switch ev.button {
							case 0:
								var tileIds = cur==null ? [] : td.getTileIdsFromRect(cur);
								openTilePickerModal(td.uid, TileRectAndClose, tileIds, false, (tids)->{
									var rect = td.getTileRectFromTileIds(tids);
									onPick(rect);
								});

							case _:
								onPick(null);
						}
					});
			}

		}
		else {
			// Invalid tileset
			jTileCanvas.addClass("empty");
		}

		return jTileCanvas;
	}


	public static function createEntityRef(ei:data.inst.EntityInstance, isBackRef=false, ?jTarget:js.jquery.JQuery) {
		var jRef = new J('<div class="entityRef"/>');
		if( jTarget!=null )
			jRef.appendTo(jTarget);

		if( ei==null ) {
			jRef.append('<div class="id">Entity not found</div>');
			jRef.append('<div class="location"> <span class="level">Unknown</span> </div>');
		}
		else {
			jRef.append('<div class="id">${ei.def.identifier}</div>');
			jRef.append('<div class="location"> <span class="level">${ei._li.level.identifier}</span> </div>');

			if( !ei._li.level.isInWorld(Editor.ME.curWorld) )
				jRef.find(".location").append(' <em>in</em> <span class="world">${ei._li.level._world.identifier}</span>');
		}

		if( isBackRef )
			jRef.addClass("isBackRef");


		return jRef;
	}


	public static function createImagePicker( project:data.Project, curRelPath:Null<String>, onSelect:(relPath:Null<String>)->Void ) : js.jquery.JQuery {
		var jWrapper = new J('<div class="imagePicker"/>');

		var fileName = curRelPath==null ? null : dn.FilePath.extractFileWithExt(curRelPath);

		function _pick(relPath:String) {
			if( relPath==null )
				return false;
			else {
				onSelect(relPath);
				return true;
			}
		}

		// Reload image
		if( curRelPath!=null ) {
			var jReload = new J('<button class="reload" title="Manually reload file"> <span class="icon refresh"/> </button>');
			jReload.appendTo(jWrapper);
			jReload.click( (_)->{
				if( curRelPath!=null ) {
					Editor.ME.project.disposeImage(curRelPath);
					_pick(curRelPath);
					N.success(L.t._("Image reloaded: ::file::", {file:fileName}));
				}
			});
		}

		// Pick image button
		var jPick = new J('<button class="pick"/>');
		jPick.appendTo(jWrapper);
		jPick.click( (_)->{
			var project = Editor.ME.project;
			var defPath = project.makeAbsoluteFilePath( dn.FilePath.extractDirectoryWithoutSlash(curRelPath, true) );
			if( defPath==null )
				defPath = project.getProjectDir();
			var path = App.ME.settings.getUiDir(project, "PickImage", defPath);
			ui.Tip.clear();

			dn.js.ElectronDialogs.openFile([".png", ".gif", ".jpg", ".jpeg", ".aseprite", ".ase"], path, function(absPath) {
				App.ME.settings.storeUiDir(project, "PickImage", dn.FilePath.extractDirectoryWithoutSlash(absPath,true));
				var relPath = project.makeRelativeFilePath(absPath);
				_pick(relPath);
			});
		});

		// Existing image assets
		var allImages = Editor.ME.project.getAllCachedImages();
		if( allImages.length>0 ) {
			var jRecall = new J('<button class="recall"> <span class="icon recall"/> </button>');
			jRecall.appendTo(jWrapper);
			jRecall.click( (ev:js.jquery.Event)->{
				var ctx = new ui.modal.ContextMenu();
				ctx.setAnchor( MA_JQuery(jRecall) );
				for( img in allImages )
					ctx.addAction({
						label: L.untranslated(img.fileName),
						cb: ()->_pick(img.relPath)
					});
			});
		}

		// Button label
		if( curRelPath!=null ) {
			var abs = Editor.ME.project.makeAbsoluteFilePath(curRelPath);
			ui.Tip.attach(jPick, abs);
			if( !NT.fileExists(abs) ) {
				jWrapper.addClass("error");
				jPick.text(L.t._("File not found!"));
			}
			else
				jPick.text(dn.FilePath.extractFileWithExt(curRelPath));
		}
		else {
			jWrapper.addClass("empty");
			jPick.text("[ No image ]");
		}

		// Remove
		var jRemove = new J('<button class="remove gray" title="Stop using this image"> <span class="icon clear"/> </button>');
		jRemove.appendTo(jWrapper);
		jRemove.click( (_)->{
			new ui.modal.dialog.Confirm(jRemove, L.t._("Stop using this image?"), true, ()->onSelect(null));
		});

		// Locate
		var jLocate = makeLocateLink(Editor.ME.project.makeAbsoluteFilePath(curRelPath), true);
		jLocate.appendTo(jWrapper);


		parseComponents(jWrapper);
		return jWrapper;
	}


	public static inline function cleanUpSearchString(v:String) {
		return v==null ? "" : StringTools.trim( v.toLowerCase() );
	}


	public static function searchStringMatches(searchQuery:String, target:String, softMatching=true) {
		searchQuery = cleanUpSearchString(searchQuery);
		target = cleanUpSearchString(target);
		if( softMatching ) {
			var si = 0;
			var ti = 0;
			while( si<searchQuery.length ) {
				if( searchQuery.charCodeAt(si)==target.charCodeAt(ti)) {
					si++;
					ti++;
				}
				else {
					ti++;
					if( ti>=target.length )
						return false;
				}
			}
			return true;
		}
		else
			return target.indexOf(searchQuery)>=0;
	}


	public static function createIntGridValue(project:data.Project, ?iv:data.DataTypes.IntGridValueDefEditor, ?rawIv:ldtk.Json.IntGridValueDef, showInt=true) : js.jquery.JQuery {
		if( iv==null )
			iv = {
				identifier: rawIv.identifier,
				value: rawIv.value,
				color: dn.Col.parseHex(rawIv.color),
				tile: rawIv.tile,
				groupUid: 0,
			}

		var jVal = new J('<div class="intGridValue"></div>');
		if( showInt )
			jVal.append('<span class="index">${iv.value}</span>');

		jVal.css({
			color: C.intToHex( iv.color.toWhite(0.5) ),
			borderColor: C.intToHex( iv.color.toWhite(0.2) ),
			backgroundColor: C.intToHex( iv.color.toBlack(0.5) ),
		});
		if( iv.tile!=null ) {
			jVal.addClass("hasIcon");
			jVal.append( project.resolveTileRectAsHtmlImg(iv.tile) );
			if( showInt )
				jVal.find(".index").css({
					color: iv.color.getAutoContrastCustom(0.4).toHex(),
					backgroundColor: iv.color.toHex(),
				});
		}
		return jVal;
	}


	public static function createOutOfBoundsRulePolicy(jSelect:js.jquery.JQuery, ld:data.def.LayerDef, curValue:Null<Int>, onChange:Int->Void) {
		// Out-of-bounds policy
		jSelect.empty();

		var sourceLd = ld.autoSourceLd==null ? ld : ld.autoSourceLd;
		var values = [null, 0].concat( sourceLd.getAllIntGridValues().map( iv->iv.value ) );
		if( curValue<0 )
			values.insert(0,-1);
		for(v in values) {
			var jOpt = new J('<option value="$v"/>');
			jOpt.appendTo(jSelect);
			switch v {
				case null: jOpt.text("This rule should not apply when reading cells outside of layer bounds (default)");
				case v if(v<0): jOpt.text("-- Pick a value --");
				case 0: jOpt.text("Empty cells");
				case _:
					var iv = sourceLd.getIntGridValueDef(v);
					jOpt.text( Std.string(v) + (iv.identifier!=null ? ' - ${iv.identifier}' : "") );
					jOpt.css({
						backgroundColor: C.intToHex( C.toBlack(iv.color, 0.4) ),
						borderColor: C.intToHex( iv.color ),
					});
			}
		}

		jSelect.change( _->{
			var v = jSelect.val()=="null" ? null : Std.parseInt(jSelect.val());
			onChange(v);
		});

		jSelect.val( curValue==null ? "null" : Std.string(curValue) );
		if( curValue!=null && curValue>0 ) {
			var iv = sourceLd.getIntGridValueDef(curValue);
			jSelect.addClass("hasValue").css({
				backgroundColor: C.intToHex( C.toBlack(iv.color, 0.4) ),
				borderColor: C.intToHex( iv.color ),
			});
		}

		return jSelect;
	}


	public static function createColorButton(?jTarget:js.jquery.JQuery, curCol:dn.Col, ?usedColorsTag:String, ?defCol:dn.Col, allowNull=false, onPick:Null<dn.Col>->Void) {
		var jColor = jTarget==null ? new J('<span></span>') : jTarget;
		jColor.empty().off();
		if( !jColor.hasClass("colorButton") )
			jColor.addClass("colorButton");

		// Current color
		var jCur = new J('<span class="curColor"></span>');
		jCur.appendTo(jColor);
		jCur.append('<span class="icon color"></span>');

		inline function _applyColor(c:dn.Col) {
			if( c==null ) {
				jCur.addClass("null");
				if( defCol!=null )
					jCur.css("background-color", defCol.toHex());
			}
			else
				jCur.css("background-color", c.toHex());
		}
		_applyColor(curCol);

		// Reset button
		if( curCol!=defCol && curCol!=null && ( defCol!=null || allowNull && curCol!=null ) ) {
			var jReset = new J('<button class="transparent reset"></button>');
			jReset.appendTo(jColor);
			jReset.append('<span class="icon reset"></span>');
			jReset.click(_->{
				curCol = allowNull ? null : defCol;
				_applyColor(curCol);
				onPick(curCol);
			});
		}

		jCur.click(_->{
			var cp = new ui.modal.dialog.ColorPicker(usedColorsTag, Const.getNicePalette(), jColor, curCol);
			cp.onValidate = (c)->{
				curCol = c;
				_applyColor(curCol);
				onPick(curCol);
			}
		});
		return jColor;
	}

	public static function applyListCustomColor(jLi:js.jquery.JQuery, col:dn.Col, isActive:Bool) {
		if( col==null ) {
			jLi.removeClass("customColor");
			return;
		}

		if( isActive ) {
			jLi.css("background-color", col.toHex());
			jLi.css("color", col.getAutoContrastCustom(0.5).toHex());
			jLi.css("box-shadow", "-4px 0 0 white inset");
		}
		else {
			jLi.css("background-color", col.toCssRgba(0.5));
			jLi.css("color", col.toWhite(0.3).toHex());
			jLi.css("box-shadow", "-4px 0 0 "+col.toHex()+" inset");
		}
		jLi.addClass("customColor");
	}
}
