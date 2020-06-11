package misc;

class JsTools {
	public static function init() {
		js.node.Require.require("fs");
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

	public static function createFieldTypeIcon(type:FieldType, withName=true, ?ctx:js.jquery.JQuery) : js.jquery.JQuery {
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


	public static function createEntityPreview(ed:EntityDef, sizePx=64) {
		var scale = sizePx/64;
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


	static var _fileCache : Map<String,String> = new Map();
	public static function clearFileCache() {
		_fileCache = new Map();
	}

	public static function getHtmlTemplate(name:String) : Null<String> {
		if( !_fileCache.exists(name) ) {
			var path = dn.FilePath.fromFile("tpl/"+name);
			path.extension = "html";

			if( !js.node.Fs.existsSync(path.full) )
				throw "File not found "+path.full;

			var buffer = js.node.Fs.readFileSync(path.full);
			_fileCache.set( name, buffer.toString() );
		}

		return _fileCache.get(name);
	}
}
