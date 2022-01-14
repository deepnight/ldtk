package misc;

import sortablejs.*;
import sortablejs.Sortable;
import js.node.Fs;

class JsTools {

	/**
		Use SortableJS to make some list sortable
		See: https://github.com/SortableJS/Sortable
	**/
	public static function makeSortable(jSortable:js.jquery.JQuery, ?jScrollRoot:js.jquery.JQuery, ?group:String, anim=true, onSort:(event:SortableDragEvent)->Void) {
		if( jSortable.length!=1 )
			throw "Used sortable on a set of "+jSortable.length+" element(s)";

		jSortable.addClass("sortable");

		// Base settings
		var settings : SortableOptions = {
			onStart: function(ev) {
				App.ME.jBody.addClass("sorting");
				new J(ev.item).addClass("dragging");
			},
			onEnd: function(ev) {
				App.ME.jBody.removeClass("sorting");
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
			filter: ".fixed",
			animation: anim ? 100 : 0,
		}

		// Custom handle
		if( jSortable.children().children(".sortHandle").length>0 ) {
			settings.handle = ".sortHandle";
			jSortable.addClass("customHandle");
		}

		Sortable.create( jSortable.get(0), settings);
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

	public static function createTile(td:data.def.TilesetDef, tileId:Int, size:Int) {
		var jCanvas = new J('<canvas></canvas>');
		jCanvas.attr("width",td.tileGridSize);
		jCanvas.attr("height",td.tileGridSize);
		jCanvas.css("width", size+"px");
		jCanvas.css("height", size+"px");
		td.drawTileToCanvas(jCanvas, tileId);
		return jCanvas;
	}


	public static function createEntityPreview(project:data.Project, ed:data.def.EntityDef, sizePx=24) {
		var jWrapper = new J('<div class="entityPreview icon"></div>');
		jWrapper.css("width", sizePx+"px");
		jWrapper.css("height", sizePx+"px");

		var scale = sizePx / M.fmax(ed.width, ed.height);

		var jCanvas = new J('<canvas></canvas>');
		jCanvas.appendTo(jWrapper);
		jCanvas.attr("width", ed.width*scale);
		jCanvas.attr("height", ed.height*scale);

		var cnv = Std.downcast( jCanvas.get(0), js.html.CanvasElement );
		var ctx = cnv.getContext2d();

		switch ed.renderMode {
			case Rectangle:
				ctx.fillStyle = C.intToHex(ed.color);
				ctx.fillRect(0, 0, ed.width*scale, ed.height*scale);

			case Cross:
				ctx.strokeStyle = C.intToHex(ed.color);
				ctx.lineWidth = 5 * js.Browser.window.devicePixelRatio;
				ctx.moveTo(0,0);
				ctx.lineTo(ed.width*scale, ed.height*scale);
				ctx.moveTo(0,ed.height*scale);
				ctx.lineTo(ed.width*scale, 0);
				ctx.stroke();

			case Ellipse:
				ctx.fillStyle = C.intToHex(ed.color);
				ctx.beginPath();
				ctx.ellipse(
					ed.width*0.5*scale, ed.height*0.5*scale,
					ed.width*0.5*scale, ed.height*0.5*scale,
					0, 0, M.PI*2
				);
				ctx.fill();

			case Tile:
				ctx.fillStyle = C.intToHex(ed.color)+"66";
				ctx.beginPath();
				ctx.rect(0, 0, Std.int(ed.width*scale), Std.int(ed.height*scale));
				ctx.fill();

				if( ed.isTileDefined() ) {
					var td = project.defs.getTilesetDef(ed.tilesetId);
					var x = 0;
					var y = 0;
					var scaleX = 1.;
					var scaleY = 1.;
					switch ed.tileRenderMode {
						case Stretch:
							scaleX = scale * ed.width / td.tileGridSize;
							scaleY = scale * ed.height / td.tileGridSize;

						case FitInside:
							var s = M.fmin(scale * ed.width / td.tileGridSize, scale * ed.height / td.tileGridSize);
							scaleX = s;
							scaleY = s;

						case Cover, Repeat:
							var s = M.fmin(scale * ed.width / td.tileGridSize, scale * ed.height / td.tileGridSize);
							scaleX = s;
							scaleY = s;
					}
					td.drawTileToCanvas( jCanvas, ed.tileId, x, y, scaleX, scaleY );
				}
		}

		return jWrapper;
	}


	public static function createPivotEditor( curPivotX:Float, curPivotY:Float, ?inputName:String, ?bgColor:UInt, onPivotChange:(pivotX:Float, pivotY:Float)->Void ) {
		var pivots = new J("xml#pivotEditor").children().first().clone();

		pivots.find("input[type=radio]").attr("name", inputName==null ? "pivot" : inputName);

		if( bgColor!=null )
			pivots.find(".bg").css( "background-color", C.intToHex(bgColor) );
		else
			pivots.find(".bg").hide();

		pivots.find("input[type=radio][value='"+curPivotX+" "+curPivotY+"']").prop("checked",true);

		pivots.find("input[type=radio]").each( function(idx:Int, elem) {
			var r = new J(elem);
			r.change( function(ev) {
				var rawPivots = r.val().split(" ");
				onPivotChange( Std.parseFloat( rawPivots[0] ), Std.parseFloat( rawPivots[1] ) );
			});
		});

		return pivots;
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
							case "mouseleft": new J('<span class="icon mouseleft"></span>');
							case "mouseright": new J('<span class="icon mouseright"></span>');
							case "mousewheel": new J('<span class="icon mousewheel"></span>');
							case "mousemiddle": new J('<span class="icon mousemiddle"></span>');

							case "+", "-", "to", "/", "or", '"', "'", "on": new J('<span class="misc">$k</span>');

							case k.charAt(0) => "(": new J("<span/>").append(k);
							case k.charAt(k.length-1) => ")": new J("<span/>").append(k);

							case _:
								var jKey = new J('<span class="key">${k.toUpperCase()}</span>');
								switch k.toLowerCase() {
									case "shift", "alt" : jKey.addClass( k.toLowerCase() );
									case "ctrl" : jKey.addClass( App.isMac() ? 'meta' : k.toLowerCase() );
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

		jTarget.empty().append( jReplace.contents() );
	}


	public static function parseComponents(jCtx:js.jquery.JQuery) {
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
				electron.Shell.openExternal(url);
			});
			link.on("auxclick", (ev:js.jquery.Event)->{
				switch ev.button {
					case 1:
						ev.preventDefault();
						electron.Shell.openExternal(url);

					case 2:
						var ctx = new ui.modal.ContextMenu(ev);
						ctx.add({
							label: L.t._("Copy URL"),
							cb: ()->{
								electron.Clipboard.write({ text:url });
								N.msg("Copied.");
							}
						});

					case _:
				}
			});
		});


		// Auto tool-tips
		jCtx.find("[title]:not([noTip]), [data-title]").each( function(idx,e) {
			var jThis = new J(e);
			var tipStr = jThis.attr("data-title");
			if( tipStr==null ) {
				tipStr =  jThis.attr("title");
				jThis.removeAttr("title");
				jThis.attr("data-title", tipStr);
			}

			// Parse key shortcut
			var keys = [];
			if( jThis.attr("keys")!=null ) {
				var rawKeys = jThis.attr("keys").split("+").map( function(k) return StringTools.trim(k).toLowerCase() );
				for(k in rawKeys) {
					switch k {
						case "ctrl" : keys.push(K.CTRL);
						case "shift" : keys.push(K.SHIFT);
						case "alt" : keys.push(K.ALT);
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
					new ui.modal.dialog.ColorPicker( jInput.attr("colorTag"), jInput );
				});
		});


		// Accordions
		jCtx.find(".accordion").each( (idx,e)->{ // TODO unfinished
			var jAccordion = new J(e);
			var jExpand = jAccordion.find(".expand:first");
			var jContent = jExpand.nextAll();
			jContent.hide();
			jExpand.addClass("collapsed");
			jExpand
				.off(".accordion")
				.on("click.accordion", _->{
					var expanded = jContent.is(":visible");
					jExpand.removeClass("collapsed");
					jExpand.removeClass("expanded");
					if( expanded ) {
						jExpand.addClass("collapsed");
						jContent.slideUp(70);
					}
					else {
						jExpand.addClass("expanded");
						jContent.slideDown(50);
					}
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

	public static function emptyDir(path:String, ?onlyExts:Array<String>) {
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
		for(f in js.node.Fs.readdirSync(path)) {
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
		return getExeDir()+"/LDtk.log";
	}

	public static function getExeDir() {
		#if !debug
		var path = ET.getExeDir();
		#else
		var path = ET.getAppResourceDir()+"/foo.exe";
		#end
		return dn.FilePath.fromFile( path ).useSlashes().directory;
	}

	public static function getSamplesDir() {
		var raw = getExeDir() + ( App.isMac() ? "/../samples" : "/samples" );
		return dn.FilePath.fromDir( raw ).directory;
	}

	public static function makeExploreLink(filePath:Null<String>, isFile:Bool) {
		var a = new J('<a class="exploreTo"/>');
		a.append('<span class="icon"/>');
		a.find(".icon").addClass( isFile ? "locate" : "folder" );
		a.click( function(ev) {
			if( filePath==null )
				N.error("No file");
			else {
				if( !NT.fileExists(filePath) )
					N.error("Sorry, but this file couldn't be found.");
				else {
					ev.preventDefault();
					ev.stopPropagation();
					ET.locate(filePath, isFile);
				}
			}
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
		selectMode: TilesetSelectionMode=Free,
		tileIds: Array<Int>,
		onPick: (tileIds:Array<Int>)->Void
	) {
		var jTileCanvas = new J('<canvas class="tile"></canvas>');

		if( tilesetId!=null ) {
			jTileCanvas.addClass("active");
			var td = Editor.ME.project.defs.getTilesetDef(tilesetId);

			if( tileIds.length==0 ) {
				// No tile selected
				jTileCanvas.addClass("empty");
			}
			else if( selectMode!=RectOnly ) {
				// Single/random tiles
				jTileCanvas.removeClass("empty");
				jTileCanvas.attr("width", td.tileGridSize);
				jTileCanvas.attr("height", td.tileGridSize);
				td.drawTileToCanvas(jTileCanvas, tileIds[0]);
				if( tileIds.length>1 && selectMode!=RectOnly ) {
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
				var m = new ui.Modal();
				m.addClass("singleTilePicker");

				var tp = new ui.Tileset(m.jContent, td, selectMode);
				tp.setSelectedTileIds(tileIds);
				if( selectMode==PickAndClose )
					tp.onSingleTileSelect = function(tileId) {
						m.close();
						onPick([tileId]);
					}
				else
					m.onCloseCb = function() {
						onPick( tp.getSelectedTileIds() );
					}
				tp.focusOnSelection(true);
			});
		}
		else {
			// Invalid tileset
			jTileCanvas.addClass("empty");
		}

		return jTileCanvas;
	}



	public static function createImagePicker( curRelPath:Null<String>, onChange : (?relPath:String)->Void ) : js.jquery.JQuery {
		var jWrapper = new J('<div class="imagePicker"/>');

		var fileName = curRelPath==null ? null : dn.FilePath.extractFileWithExt(curRelPath);

		function _load(relPath:String) {
			var img = Editor.ME.project.getOrLoadImage(relPath);
			if( img!=null ) {
				onChange(relPath);
				return true;
			}
			else {
				N.error('Couldn\'t read image file: $relPath');
				return false;
			}
		}

		function _pickImage(relPath:String) {
			if( relPath==null )
				return false;

			return _load(relPath);
		}

		// Reload image
		if( curRelPath!=null ) {
			var jReload = new J('<button class="reload" title="Manually reload file"> <span class="icon refresh"/> </button>');
			jReload.appendTo(jWrapper);
			jReload.click( (_)->{
				if( _load(curRelPath) )
					N.success(L.t._("Image reloaded: ::file::", {file:fileName}));
			});
		}

		// Pick image button
		var jPick = new J('<button class="pick"/>');
		jPick.appendTo(jWrapper);
		jPick.click( (_)->{
			var project = Editor.ME.project;
			var path = project.makeAbsoluteFilePath( dn.FilePath.extractDirectoryWithoutSlash(curRelPath, true) );
			if( path==null )
				path = project.getProjectDir();

			ui.Tip.clear();

			dn.js.ElectronDialogs.openFile([".png", ".gif", ".jpg", ".jpeg", ".aseprite", ".ase"], path, function(absPath) {
				var relPath = project.makeRelativeFilePath(absPath);
				_pickImage(relPath);
			});
		});

		// Existing image assets
		var allImages = Editor.ME.project.getAllCachedImages();
		if( allImages.length>0 ) {
			var jRecall = new J('<button class="recall"> <span class="icon recall"/> </button>');
			jRecall.appendTo(jWrapper);
			jRecall.click( (ev:js.jquery.Event)->{
				var ctx = new ui.modal.ContextMenu();
				ctx.positionNear(jRecall);
				for( img in allImages )
					ctx.add({
						label: L.untranslated(img.fileName),
						cb: ()->_pickImage(img.relPath)
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
			new ui.modal.dialog.Confirm(jRemove, L.t._("Stop using this image?"), true, onChange.bind(null));
		});

		// Locate
		var jLocate = makeExploreLink(Editor.ME.project.makeAbsoluteFilePath(curRelPath), true);
		jLocate.appendTo(jWrapper);


		parseComponents(jWrapper);
		return jWrapper;
	}
}
