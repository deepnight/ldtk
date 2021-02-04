import dn.data.GetText;

class Lang {
	// Text constants
	public static var _Duplicate = ()->t._("Duplicate");
	public static var _Delete = ()->t._("Delete");


	// Misc
	static var _initDone = false;
	static var DEFAULT = "en";
	public static var CUR = "??";
	public static var t : GetText;


	public static function init(?lid:String) {
		if( _initDone )
			return;

		_initDone = true;
		CUR = lid==null ? DEFAULT : lid;

		t = new GetText();
		t.readMo( hxd.Res.load("lang/"+CUR+".mo").entry.getBytes() );
	}

	public static inline function onOff(v:Null<Bool>) {
		return v==true ? t._("ON") : t._("off");
	}

	public static function untranslated(str:Dynamic) : LocaleString {
		init();
		return t.untranslated(str);
	}

	public static function getLayerType(type:ldtk.Json.LayerType) : LocaleString {
		return switch type {
			case IntGrid: Lang.t._("Integer grid");
			case AutoLayer: Lang.t._("Auto-layer");
			case Entities: Lang.t._("Entities");
			case Tiles: Lang.t._("Tiles");
		}
	}

	public static function getFieldType(type:data.DataTypes.FieldType) : LocaleString {
		return switch type {
			case F_Int: t._("Integer");
			case F_Color: t._("Color");
			case F_Float: t._("Float");
			case F_String: t._("String");
			case F_Text: t._("Multilines");
			case F_Bool: t._("Boolean");
			case F_Point: t._("Point");
			case F_Enum(name): name==null ? t._("Enum") : t._("Enum.::e::", { e:name });
			case F_Path: t._("File path");
		}
	}

	public static function getFieldTypeShortName(type:data.DataTypes.FieldType) : LocaleString {
		return switch type {
			case F_Int: t._("123");
			case F_Color: t._("Col");
			case F_Float: t._("1.0");
			case F_String: t._("\"Ab\"");
			case F_Text: t._("\"\\n\\n\"");
			case F_Bool: t._("✔");
			case F_Point: t._("X::sep::Y", { sep:Const.POINT_SEPARATOR });
			case F_Enum(name): t._("Enu");
			case F_Path: t._("*.*");
		}
	}


	public static function getTextLanguageMode(m:Null<ldtk.Json.TextLanguageMode>) : LocaleString {
		return switch m {
			case null: t._("Plain text");

			case LangJson: t._("JSON");
			case LangXml: t._("XML/HTML");
			case LangMarkdown: t._("Markdown");

			case LangPython: t._("Python");
			case LangRuby: t._("Ruby");
			case LangC: t._("C/C++/C#");
			case LangHaxe: t._("Haxe");
			case LangJS: t._("Javascript");
			case LangLua: t._("LUA");
		}
	}


	public static function atlasLoadingMessage(filePath:String, result:AtlasLoadingResult) : LocaleString {
		var name = dn.FilePath.fromFile(filePath).fileWithExt;
		return switch result {
			case Ok:
				Lang.t._("Tileset image ::name:: updated.", { name:name } );

			case FileNotFound:
				Lang.t._("File not found: ::name::", { name:name } );

			case LoadingFailed(err):
				Lang.t._("Couldn't read file: ::name::", { name:name } );

			case TrimmedPadding:
				Lang.t._("\"::name::\" image was modified but it was SMALLER than the old version.\nLuckily, the tileset had some PADDING, so I was able to use it to compensate the difference.\nSo everything is ok, have a nice day ♥️", { name:name } );

			case RemapLoss:
				Lang.t._("\"::name::\" image was updated, but the new version is smaller than the previous one.\nSome tiles might have been lost in the process. It is recommended to check this carefully before saving this project!", { name:name } );

			case RemapSuccessful:
				Lang.t._("Tileset image \"::name::\" was reloaded and is larger than the old one.\nTiles coordinates were remapped, everything is ok :)", { name:name } );
		}
	}


	static var MONTHS = [ "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" ];
	public static function date(date:Date) : LocaleString {
		var day = date.getDate();
		return untranslated(
			MONTHS[ date.getMonth()+1 ]
			+" " + day + ( day==1?"st" : day==2?"nd" : day==3?"rd" : "th" )
			+" " + date.getFullYear()
			+" "+t._("at")
			+' ${dn.Lib.leadingZeros(date.getHours())}:${dn.Lib.leadingZeros(date.getMinutes())}'
		);
	}

	public static function relativeDate(d:Date) : LocaleString {
		var deltaS = Std.int( ( Date.now().getTime() - d.getTime() ) / 1000 );
		if( deltaS<0 )
			return date(d);

		if( deltaS<60 )
			return '$deltaS seconds ago';
		else if( deltaS<60*60 ) {
			var m = Std.int( deltaS/60 );
			return m<=1 ? '1 minute ago' : '$m minutes ago';
		}
		else if( deltaS<60*60*24 ) {
			var h = Std.int( deltaS / (60*60) );
			return h<=1 ? '1 hour ago' : '$h hours ago';
		}
		else
			return date(d);
	}
}