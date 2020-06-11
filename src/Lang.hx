import dn.data.GetText;

class Lang {
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

    public static function untranslated(str:Dynamic) : LocaleString {
        init();
        return t.untranslated(str);
    }

    public static function getFieldType(type:FieldType) : LocaleString {
        return switch type {
            case F_Int: t._("Integer");
            case F_Color: t._("Color");
            case F_Float: t._("Float");
            case F_String: t._("String");
            case F_Bool: t._("Boolean");
        }
    }

    public static function getFieldTypeShortName(type:FieldType) : LocaleString {
        return switch type {
            case F_Int: t._("123");
            case F_Color: t._("Red");
            case F_Float: t._("1.0");
            case F_String: t._("\"Ab\"");
            case F_Bool: t._("✔");
        }
    }
}