import dn.data.GetText;

class Lang {
	// Text constants
	public static var LANGUAGES = [
		{ id: "en", label: "English" },
		{ id: "zh-CN", label: "简体中文" },
		{ id: "ja", label: "日本語" },
		{ id: "fr", label: "Français" },
		{ id: "es", label: "Español" },
		{ id: "de", label: "Deutsch" },
	];

	// Text constants
	public static var _Untagged = ()->t._("Untagged");
	public static var _Duplicate = (?v:String) -> v==null ? t._("Duplicate") : t._("Duplicate ::e::", {e:v});
	public static var _Copy = (?v:String) -> v==null ? t._("Copy") : t._("Copy ::e::", {e:v});
	public static var _Cut = (?v:String) -> v==null ? t._("Cut") : t._("Cut ::e::", {e:v});
	public static var _Paste = (?v:String) -> v==null ? t._("Paste") : t._("Paste ::e::", {e:v});
	public static var _PasteAfter = (?v:String) -> v==null ? t._("Paste after") : t._("Paste ::e:: after", {e:v});
	public static var _Delete = (?v:String) -> v==null ? t._("Delete") : t._("Delete ::e::", {e:v});
	public static var _UnsupportedWinNetDir = ()->L.t._("Sorry but LDtk does not support working on a Network Drive yet.\nSo, for your own safety, operations on Network Drives are not permitted for now to avoid errors and potential data loss.");


	// Misc
	static var _initDone = false;
	public static var DEFAULT = "en";
	public static var CUR = "??";
	public static var t : GetText;

	static var _spaceRegex = ~/[\r\n\t]+/g;
	static var _multiSpaceRegex = ~/[ ]{2,}/g;

	public static function init(?lid:String) {
		if( _initDone ) {
			if( lid==null || lid=="" || lid==CUR )
				return;
			setLanguage(lid);
			return;
		}

		if( lid!=null && lid!="" )
			setLanguage(lid);
		else {
			#if editor
			var detected = App.ME!=null && App.ME.settings!=null ? App.ME.settings.getLocale() : (new Settings()).getLocale();
			setLanguage(detected);
			#else
			setLanguage(DEFAULT);
			#end
		}
	}

	public static function setLanguage(lid:String) {
		if( lid==null || lid=="" ) {
			#if editor
			lid = App.ME!=null && App.ME.settings!=null ? App.ME.settings.getLocale() : (new Settings()).getLocale();
			#else
			lid = DEFAULT;
			#end
		}
		if( lid==null || lid=="" )
			lid = DEFAULT;

		CUR = lid;
		var newT = new GetText();
		_initDone = true;

		var loaded = false;
		#if (electron || nodejs)
		try {
			var appDir = dn.js.ElectronTools.getAppResourceDir();
			// Check assets/lang/ first (packaged app)
			var pAssets = dn.FilePath.fromFile(appDir + "assets/lang/" + CUR + ".po");
			if( dn.js.NodeTools.fileExists(pAssets.full) ) {
				var bytes = dn.js.NodeTools.readFileBytes(pAssets.full);
				newT.readPo(bytes);
				loaded = true;
			}
			// Check res/lang/ (development / unpackaged)
			if( !loaded ) {
				var pRes = dn.FilePath.fromFile(appDir + "res/lang/" + CUR + ".po");
				if( dn.js.NodeTools.fileExists(pRes.full) ) {
					var bytes = dn.js.NodeTools.readFileBytes(pRes.full);
					newT.readPo(bytes);
					loaded = true;
				}
			}
		} catch(_) {}
		#end

		if( !loaded ) {
			try {
				newT.readPo( hxd.Res.load("lang/"+CUR+".po").entry.getBytes() );
				loaded = true;
			} catch(e:Dynamic) {
				// Failed to load CUR. Do NOT clobber with DEFAULT/en.po if we already have a loaded dictionary
				if( CUR==DEFAULT && (t==null || !t.getRawDict().keys().hasNext()) ) {
					try {
						newT.readPo( hxd.Res.load("lang/"+DEFAULT+".po").entry.getBytes() );
						loaded = true;
					} catch(_) {}
				}
			}
		}

		if( loaded || t==null )
			t = newT;
	}

	public static function getText(str:Null<String>, ?vars:Dynamic) : String {
		if( str==null || str.length==0 )
			return str;

		if( t==null )
			init();

		var trimmed = StringTools.trim(str);
		if( trimmed.length==0 )
			return str;

		var dict = t.getRawDict();
		if( dict.exists(trimmed) )
			return t.get(trimmed, vars);

		if( dict.exists(str) )
			return t.get(str, vars);

		var normalized = _multiSpaceRegex.replace( _spaceRegex.replace(trimmed, " "), " " );
		if( dict.exists(normalized) )
			return t.get(normalized, vars);

		// Handle \n vs \\n representation differences
		if( trimmed.indexOf("\\n")>=0 ) {
			var withRealNewlines = StringTools.replace(trimmed, "\\n", "\n");
			if( dict.exists(withRealNewlines) )
				return t.get(withRealNewlines, vars);
		}
		if( trimmed.indexOf("\n")>=0 ) {
			var withEscapedNewlines = StringTools.replace(trimmed, "\n", "\\n");
			if( dict.exists(withEscapedNewlines) )
				return t.get(withEscapedNewlines, vars);
		}

		return t.get(str, vars);
	}

	#if (electron || nodejs)
	public static function localizeDom(jCtx:js.jquery.JQuery) : Void {
		if( jCtx==null || t==null || CUR=="en" )
			return;

		// Localize attributes: title, placeholder, data-title
		jCtx.find("[title], [placeholder], [data-title]").addBack("[title], [placeholder], [data-title]").each( function(idx, el) {
			var jEl = new js.jquery.JQuery(el);
			var title = jEl.attr("title");
			if( title!=null && title!="" && !StringTools.startsWith(title, "http") && !StringTools.startsWith(title, "mailto:") ) {
				var trans = getText(title);
				if( trans!=title )
					jEl.attr("title", trans);
			}
			var dataTitle = jEl.attr("data-title");
			if( dataTitle!=null && dataTitle!="" && !StringTools.startsWith(dataTitle, "http") && !StringTools.startsWith(dataTitle, "mailto:") ) {
				var trans = getText(dataTitle);
				if( trans!=dataTitle )
					jEl.attr("data-title", trans);
			}
			var placeholder = jEl.attr("placeholder");
			if( placeholder!=null && placeholder!="" ) {
				var trans = getText(placeholder);
				if( trans!=placeholder )
					jEl.attr("placeholder", trans);
			}
		});

		// Localize text nodes and options across all UI elements
		jCtx.find("*").addBack().each( function(idx, el) {
			var domEl : js.html.Element = cast el;
			if( domEl==null )
				return;

			var tag = domEl.tagName.toLowerCase();
			if( tag=="script" || tag=="style" || tag=="code" || tag=="pre" || tag=="canvas" || tag=="svg" || tag=="input" || tag=="textarea" )
				return;

			if( domEl.classList!=null && (domEl.classList.contains("icon") || domEl.classList.contains("key") || domEl.classList.contains("code")) )
				return;

			// Handle <option> elements in select dropdowns
			if( tag=="option" ) {
				var opt : js.html.OptionElement = cast domEl;
				var rawText = opt.text;
				if( rawText!=null && rawText.length>0 ) {
					var trimmed = StringTools.trim(rawText);
					if( trimmed.length>0 ) {
						var trans = getText(trimmed);
						if( trans!=trimmed )
							opt.text = trans;
					}
				}
				return;
			}

			// Localize direct text nodes
			if( domEl.childNodes!=null ) {
				for(i in 0...domEl.childNodes.length) {
					var node = domEl.childNodes.item(i);
					if( node.nodeType == 3 ) { // Node.TEXT_NODE
						var rawVal = node.nodeValue;
						if( rawVal==null )
							continue;
						var trimmed = StringTools.trim(rawVal);
						if( trimmed.length==0 )
							continue;

						var trans = getText(trimmed);
						if( trans!=trimmed ) {
							var len = rawVal.length;
							var start = 0;
							while( start<len ) {
								var c = rawVal.charCodeAt(start);
								if( c==32 || c==9 || c==10 || c==13 ) start++; else break;
							}
							var end = len;
							while( end>start ) {
								var c = rawVal.charCodeAt(end-1);
								if( c==32 || c==9 || c==10 || c==13 ) end--; else break;
							}
							var leading = rawVal.substring(0, start);
							var trailing = rawVal.substring(end);
							node.nodeValue = leading + trans + trailing;
						}
					}
				}
			}
		});
	}
	#end

	public static inline function onOff(v:Null<Bool>) {
		return v==true ? t._("ON") : t._("off");
	}

	public static function untranslated(str:Dynamic) : LocaleString {
		if( str==null )
			return null;
		else {
			if( t==null )
				init();
			return t.untranslated(str);
		}
	}

	public static function getLayerType(type:ldtk.Json.LayerType) : LocaleString {
		return switch type {
			case IntGrid: Lang.t._("Integer grid");
			case AutoLayer: Lang.t._("Auto-layer");
			case Entities: Lang.t._("Entities");
			case Tiles: Lang.t._("Tiles");
		}
	}

	public static function getFieldType(type:ldtk.Json.FieldType) : LocaleString {
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
			case F_EntityRef: t._("Entity ref");
			case F_Tile: t._("Tile");
		}
	}

	public static function getFieldTypeShortName(type:ldtk.Json.FieldType) : LocaleString {
		return switch type {
			case F_Int: t._("123");
			case F_Color: t._("Col");
			case F_Float: t._("1.0");
			case F_String: t._("\"Ab\"");
			case F_Text: t._("\"Ab\\n\"");
			case F_Bool: t._("✔");
			case F_Point: t._("X::sep::Y", { sep:Const.POINT_SEPARATOR });
			case F_Enum(name): t._("Enu");
			case F_Path: t._("*.*");
			case F_EntityRef: t._("Ent");
			case F_Tile: t._("Tile");
		}
	}


	public static function getEmbedAtlasInfos(e:ldtk.Json.EmbedAtlas) {
		return switch e {
			case LdtkIcons: {
				displayName: "⚙️ Internal icons by FinalBossBlues",
				identifier: "Internal_Icons",
				author: "FinalBossBlues",
				support: { label:"Patreon", url:"https://www.patreon.com/finalbossblues" },
				url: "https://finalbossblues.itch.io/icons"
			}
		}
	}


	public static function getTextLanguageMode(m:Null<ldtk.Json.TextLanguageMode>) : LocaleString {
		return switch m {
			case null: t._("Plain text");

			case LangJson: t._("JSON");
			case LangXml: t._("XML/HTML");
			case LangMarkdown: t._("Markdown");

			case LangLog: t._("Log file");

			case LangPython: t._("Python");
			case LangRuby: t._("Ruby");
			case LangC: t._("C/C++/C#");
			case LangHaxe: t._("Haxe");
			case LangJS: t._("Javascript");
			case LangLua: t._("Lua");
		}
	}


	public static function imageLoadingMessage(filePath:String, result:ImageLoadingResult) : LocaleString {
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
				Lang.t._("Tileset image \"::name::\" was reloaded and the new version was larger than the old one.\nTiles coordinates were remapped, everything is ok :)", { name:name } );

			case UnsupportedFileOrigin(origin):
				Lang.t._("Loading from the following source is not supported: ::origin::", {origin:origin});
		}
	}


	static var MONTHS = [ "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" ];
	public static function date(date:Date) : LocaleString {
		var day = date.getDate();
		return untranslated(
			MONTHS[ date.getMonth() ]
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
			return t._('::s:: seconds ago', {s:deltaS});
		else if( deltaS<60*60 ) {
			var m = Std.int( deltaS/60 );
			return m<=1
				? t._('1 minute ago')
				: t._('::m:: minutes ago', {m:m});
		}
		else if( deltaS<60*60*24 ) {
			var h = Std.int( deltaS / (60*60) );
			return h<=1
				? t._('1 hour ago')
				: t._('::h:: hours ago', {h:h});
		}
		else
			return date(d);
	}
}
