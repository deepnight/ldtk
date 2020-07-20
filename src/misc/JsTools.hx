package misc;

class JsTools {
	public static function init() {
	}

	public static function makeSortable(selector:String, onSort:(from:Int, to:Int)->Void) {
		js.Lib.eval('sortable("$selector")');
		new J(selector)
			.off("sortupdate")
			.on("sortupdate", function(ev) {
				var from : Int = ev.detail.origin.index;
				var to : Int = ev.detail.destination.index;
				onSort(from,to);
				// var moved = project.sortLayerDef(from,to);
				// selectLayer(moved);
				// client.ge.emit(LayerDefSorted);
			}
		);
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


	public static function createEntityPreview(ed:led.def.EntityDef, sizePx=40) {
		var scale = sizePx/40;
		var ent = new J('<div/>');
		ent.addClass("entity");
		ent.css("width", ed.width*scale);
		ent.css("height", ed.height*scale);
		ent.css("background-color", C.intToHex(ed.color));

		var wrapper = ent.wrap("<div/>").parent();
		wrapper.addClass("icon entityPreview");
		wrapper.width(sizePx);
		wrapper.height(sizePx);

		// if( scale!=1 )
			// wrapper.css("transform","scale("+scale+")");

		return wrapper;
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

	public static function getHtmlTemplate(name:String) : Null<String> {
		if( !_fileCache.exists(name) ) {
			var path = dn.FilePath.fromFile(Boot.APP_ROOT + "tpl/" + name);
			path.extension = "html";

			if( !fileExists(path.full) )
				throw "File not found "+path.full;

			_fileCache.set( name, readFileString(path.full) );
		}

		return _fileCache.get(name);
	}


	static function getTmpFileInput() {
		var input = new J("input#tmpFileInput");
		if( input.length==0 ) {
			input = new J("<input/>");
			input.attr("type","file");
			input.attr("id","tmpFileInput");
			input.appendTo( new J("body") );
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

	public static function loadDialog(?fileTypes:Array<String>, onLoad:(filePath:String)->Void) {
		var input = getTmpFileInput();

		if( fileTypes==null || fileTypes.length==0 )
			fileTypes = [".*"];
		input.attr("accept", fileTypes.join(","));

		input.change( function(ev) {
			var path = input.val();
			input.remove();
			onLoad(path);
		});
		input.click();
	}

	public static function saveAsDialog(?fileTypes:Array<String>, onFileSelect:(filePath:String)->Void) {
		var input = getTmpFileInput();

		if( fileTypes==null || fileTypes.length==0 )
			fileTypes = [".*"];
		input.attr("accept", fileTypes.join(","));
		input.attr("nwsaveas","nwsaveas");

		input.change( function(ev) {
			var path = input.val();
			input.remove();
			onFileSelect(path);
		});
		input.click();
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
		jCtx.find(".info").each( function(idx, e) {
			var jElem = new J(e);
			if( jElem.data("str")==null ) {
				if( jElem.hasClass("identifier") )
					jElem.data( "str", L.t._("An identifier should be UNIQUE and only contain LETTERS, NUMBERS or UNDERSCORES (ie. \"_\").") );
				else
					jElem.data("str", jElem.text());
				jElem.empty();
			}
			ui.Tip.attach(jElem, jElem.data("str"), "infoTip");
		});
	}


	// *** File API (NWJS) **************************************

	#if hxnodejs

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

	public static function setCwd(dir:String) {
		var fp = dn.FilePath.fromDir(dir);
		if( isWindows() )
			fp.useBackslashes();
		else
			fp.useSlashes();
		js.Node.process.chdir(fp.full);
	}

	public static function getCwd() {
		return js.Node.process.cwd();
	}

	public static function exploreToFile(filePath:String) {
		var fp = dn.FilePath.fromFile(filePath);
		if( isWindows() )
			fp.useBackslashes();
		N.debug(fp.full);
		nw.Shell.showItemInFolder(fp.full);
	}

	public static function isWindows() {
		N.debug( js.Node.process.platform );
		return js.Node.process.platform.toLowerCase().indexOf("win")==0;
	}

	#end

}
