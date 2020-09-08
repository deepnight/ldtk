package misc;

class JsTools {
	public static function makeSortable(selector:String, onSort:(from:Int, to:Int)->Void) {
		// TODO replace html5sortable with corresponding npm module
		if( new J(selector).find(".dragHandle").length>0 )
			js.Lib.eval('sortable("$selector", { items:":not(.fixed)", handle:".dragHandle" })');
		else
			js.Lib.eval('sortable("$selector", { items:":not(.fixed)" })');

		new J(selector)
			.off("sortupdate")
			.on("sortupdate", function(ev) {
				var from : Int = ev.detail.origin.index;
				var to : Int = ev.detail.destination.index;
				onSort(from,to);
			}
		);
	}

	public static function prepareProjectFile(p:led.Project) : { bytes:haxe.io.Bytes, json:Dynamic } {
		var json = p.toJson();
		var jsonStr = dn.JsonPretty.stringify(json, Const.JSON_HEADER);

		return {
			bytes: haxe.io.Bytes.ofString( jsonStr ),
			json: json,
		}
	}

	public static function createLayerTypeIcon(type:led.LedTypes.LayerType, withName=true, ?ctx:js.jquery.JQuery) : js.jquery.JQuery {
		var wrapper = new J('<span class="layerType"/>');

		var icon = new J('<span class="icon"/>');
		icon.appendTo(wrapper);
		icon.addClass( switch type {
			case IntGrid: "intGrid";
			case Entities: "entity";
			case Tiles: "tile";
		});

		if( withName ) {
			var name = new J('<span class="name"/>');
			name.text( L.getLayerType(type) );
			name.appendTo(wrapper);
		}

		if( ctx!=null )
			wrapper.appendTo(ctx);
		return wrapper;
	}

	public static function createFieldTypeIcon(type:led.LedTypes.FieldType, withName=true, ?ctx:js.jquery.JQuery) : js.jquery.JQuery {
		var icon = new J("<span/>");
		icon.addClass("icon fieldType");
		icon.addClass(type.getName());
		if( withName )
			icon.append('<span class="typeName">'+L.getFieldType(type)+'</span>');
		icon.append('<span class="typeIcon">'+L.getFieldTypeShortName(type)+'</span>');

		if( ctx!=null )
			icon.appendTo(ctx);

		return icon;
	}

	public static function createTile(td:led.def.TilesetDef, tileId:Int, size:Int) {
		var jCanvas = new J('<canvas></canvas>');
		jCanvas.attr("width",td.tileGridSize);
		jCanvas.attr("height",td.tileGridSize);
		jCanvas.css("width", size+"px");
		jCanvas.css("height", size+"px");
		td.drawTileToCanvas(jCanvas, tileId);
		return jCanvas;
	}


	public static function createEntityPreview(project:led.Project, ed:led.def.EntityDef, sizePx=24) {
		var jWrapper = new J('<div class="entityPreview icon"></div>');
		jWrapper.css("width", sizePx+"px");
		jWrapper.css("height", sizePx+"px");

		var scale = sizePx / M.fmax(ed.width, ed.height);

		var jCanvas = new J('<canvas></canvas>');
		jCanvas.appendTo(jWrapper);
		jCanvas.attr("width", ed.width*scale);
		jCanvas.attr("height", ed.height*scale);
		// jCanvas.css("zoom", sizePx / M.fmax(ed.width, ed.height));

		var cnv = Std.downcast( jCanvas.get(0), js.html.CanvasElement );
		var ctx = cnv.getContext2d();

		switch ed.renderMode {
			case Rectangle:
				ctx.fillStyle = C.intToHex(ed.color);
				ctx.fillRect(0, 0, ed.width*scale, ed.height*scale);

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
				ctx.strokeStyle = C.intToHex(ed.color);
				ctx.beginPath();
				ctx.rect(0, 0, Std.int(ed.width*scale), Std.int(ed.height*scale));
				ctx.stroke();

				if( ed.isTileValid() ) {
					var td = project.defs.getTilesetDef(ed.tilesetId);
					td.drawTileToCanvas(
						jCanvas, ed.tileId,
						Std.int(ed.width*ed.pivotX*scale - td.tileGridSize*ed.pivotX*scale),
						Std.int(ed.height*ed.pivotY*scale - td.tileGridSize*ed.pivotY*scale),
						scale
					);
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
	public static function clearFileCache() {
		_fileCache = new Map();
	}

	public static function getHtmlTemplate(name:String, ?vars:Dynamic) : Null<String> {
		if( !_fileCache.exists(name) ) {
			var path = dn.FilePath.fromFile(App.RESOURCE_DIR + "tpl/" + name);
			path.extension = "html";

			if( !fileExists(path.full) )
				throw "File not found "+path.full;

			_fileCache.set( name, readFileString(path.full) );
		}

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

		return new J('<span class="key">$keyLabel</span>');
	}


	public static function parseComponents(jCtx:js.jquery.JQuery) {
		// (i) Info bubbles
		jCtx.find(".info").each( function(idx, e) {
			var jThis = new J(e);

			if( jThis.data("str")==null ) {
				if( jThis.hasClass("identifier") )
					jThis.data( "str", L.t._("An identifier should be UNIQUE (in this context) and can only contain LETTERS, NUMBERS or UNDERSCORES (ie. \"_\").") );
				else
					jThis.data("str", jThis.text());
				jThis.empty();
			}
			ui.Tip.attach(jThis, jThis.data("str"), "infoTip");
		});

		// External links
		var links = jCtx.find("a[href], button[href]");
		links.each( function(idx,e) {
			var link = new J(e);
			var url = link.attr("href");
			ui.Tip.attach(link, url, true);
			link.click( function(ev) {
				ev.preventDefault();
				electron.Shell.openExternal(url);
			});
		});


		// Auto tool-tips
		jCtx.find("[title], [data-title]").each( function(idx,e) {
			var jThis = new J(e);
			var tip = jThis.attr("data-title");
			if( tip==null ) {
				tip =  jThis.attr("title");
				jThis.removeAttr("title");
				jThis.attr("data-title", tip);
			}

			// Parse key shortcut
			var keys = [];
			if( jThis.attr("keys")!=null ) {
				var rawKeys = jThis.attr("keys").split("+").map( function(k) return StringTools.trim(k).toLowerCase() );
				jThis.removeAttr("keys");
				for(k in rawKeys) {
					switch k {
						case "ctrl" : keys.push(K.CTRL);
						case "shift" : keys.push(K.SHIFT);
						case "alt" : keys.push(K.ALT);
						case _ :
							if( k.length==1 ) {
								var cid = k.charCodeAt(0);
								if( cid>="a".code && cid<="z".code )
									keys.push( cid - "a".code + K.A );
							}
					}
				}
			}

			ui.Tip.attach( jThis, tip, keys );
		});
	}


	public static function makePath(path:String) {
		path = StringTools.replace(path,"\\","/");
		var parts = path.split("/").map( function(p) {
			var chksum = 0;
			for(i in 0...p.length)
				chksum+=p.charCodeAt(i);
			var col = C.makeColorHsl( (chksum/100) % 0.5, 0.6, 1.0 );
			return '<span style="color: ${C.intToHex(col)}">$p</span>';
		});
		var e = new J( parts.join('<span class="slash">/</span>') );
		return e.wrapAll('<div class="path"/>').parent();
	}


	// *** File API (node) **************************************

	public static function fileExists(path:String) {
		if( path==null )
			return false;
		else {
			js.node.Require.require("fs");
			return js.node.Fs.existsSync(path);
		}
	}

	public static function readFileString(path:String) : Null<String> {
		if( !fileExists(path) )
			return null;
		else
			return js.node.Fs.readFileSync(path).toString();
	}

	public static function readFileBytes(path:String) : Null<haxe.io.Bytes> {
		if( !fileExists(path) )
			return null;
		else
			return js.node.Fs.readFileSync(path).hxToBytes();
	}

	public static function writeFileBytes(path:String, bytes:haxe.io.Bytes) {
		js.node.Require.require("fs");
		js.node.Fs.writeFileSync( path, js.node.Buffer.hxFromBytes(bytes) );
	}

	public static function getAppDir() {
		#if electron

		var path = electron.renderer.IpcRenderer.sendSync("getAppDir");
		return dn.FilePath.fromDir( path ).useSlashes().directory;

		#else

		return js.Node.process.cwd();

		#end
	}

	public static function getCwd() {
		#if electron

		var path = electron.renderer.IpcRenderer.sendSync("getCwd");
		return dn.FilePath.fromDir( path ).useSlashes().directory;

		#else

		return js.Node.process.cwd();

		#end
	}

	public static function exploreToFile(filePath:String) {
		var fp = dn.FilePath.fromFile(filePath);
		if( isWindows() )
			fp.useBackslashes();

		if( !fileExists(fp.full) )
			fp.fileWithExt = null;

		#if nwjs
		nw.Shell.showItemInFolder(fp.full);
		#else
		electron.Shell.showItemInFolder(fp.full);
		#end
	}

	public static function makeExploreLink(filePath:String) {
		var a = new J('<a class="exploreTo"/>');
		a.click( function(ev) {
			ev.preventDefault();
			ev.stopPropagation();
			exploreToFile(filePath);
		});
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


	public static function createTilePicker(tilesetId:Null<Int>, singleMode=false, tileIds:Array<Int>, onPick:(tileIds:Array<Int>)->Void) {
		var jTile = new J('<canvas class="tile"></canvas>');

		if( tilesetId!=null ) {
			jTile.addClass("active");
			var td = Editor.ME.project.defs.getTilesetDef(tilesetId);

			// Render tile
			if( tileIds.length>0 ) {
				jTile.removeClass("empty");
				jTile.attr("width", td.tileGridSize);
				jTile.attr("height", td.tileGridSize);
				td.drawTileToCanvas(jTile, tileIds[0]);
			}
			else
				jTile.addClass("empty");

			// Open picker
			jTile.click( function(ev) {
				var m = new ui.Modal();
				m.addClass("singleTilePicker");

				var tp = new ui.TilesetPicker(m.jContent, td);
				if( singleMode )
					tp.mode = SingleTile;
				tp.setSelectedTileIds(tileIds);
				if( singleMode )
					tp.onSingleTileSelect = function(tileId) {
						m.close();
						onPick([tileId]);
					}
				else
					m.onCloseCb = function() {
						onPick( tp.getSelectedTileIds() );
					}
			});
		}
		else
			jTile.addClass("empty");

		return jTile;
	}


	public static function createAutoPatternGrid(rule:led.LedTypes.AutoLayerRule, layerDef:led.def.LayerDef, previewMode=false, ?onClick:(coordId:Int, button:Int)->Void) {
		var jGrid = new J('<div class="autoPatternGrid"/>');
		jGrid.css("grid-template-columns", 'repeat( ${Const.AUTO_LAYER_PATTERN_SIZE}, auto )');

		if( onClick!=null )
			jGrid.addClass("editable");

		if( previewMode )
			jGrid.addClass("preview");

		var idx = 0;
		for(cy in 0...Const.AUTO_LAYER_PATTERN_SIZE)
		for(cx in 0...Const.AUTO_LAYER_PATTERN_SIZE) {
			var coordId = cx+cy*Const.AUTO_LAYER_PATTERN_SIZE;
			var isCenter = cx==Std.int(Const.AUTO_LAYER_PATTERN_SIZE/2) && cy==Std.int(Const.AUTO_LAYER_PATTERN_SIZE/2);

			var jCell = new J('<div class="cell"/>');
			jCell.appendTo(jGrid);
			if( onClick!=null )
				jCell.addClass("editable");

			// Center
			if( isCenter ) {
				jCell.addClass("center");
				if( previewMode ) {
					var td = Editor.ME.project.defs.getTilesetDef( layerDef.autoTilesetDefUid );
					if( td!=null ) {
						var jTile = createTile(td, rule.tileIds[0], 32);
						jCell.append(jTile);
						jCell.addClass("tilePreview");
					}
				}
			}

			// Cell color
			if( !isCenter || !previewMode ) {
				var v = rule.pattern[coordId];
				if( v!=null ) {
					if( v>0 ) {
						if( M.iabs(v)-1 == Const.AUTO_LAYER_ANYTHING )
							jCell.addClass("anything");
						else
							jCell.css("background-color", C.intToHex( layerDef.getIntGridValueDef(M.iabs(v)-1).color ) );
					}
					else {
						jCell.addClass("not").append('<span class="cross">x</span>');
						if( M.iabs(v)-1 == Const.AUTO_LAYER_ANYTHING )
							jCell.addClass("anything");
						else
							jCell.css("background-color", C.intToHex( layerDef.getIntGridValueDef(M.iabs(v)-1).color ) );
					}
				}
				else
					jCell.addClass("empty");
			}

			// Edit grid value
			if( onClick!=null )
				jCell.mousedown( function(ev) {
					onClick(coordId, ev.button);
				});

			idx++;
		}

		return jGrid;
	}
}
