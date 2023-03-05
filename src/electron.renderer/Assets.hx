#if !macro

class Assets {
	static var fontLight_tiny : h2d.Font;
	static var fontLight_regular : h2d.Font;
	static var fontLight_large : h2d.Font;
	public static var fontLight_title : h2d.Font;
	public static var fontPixel : h2d.Font;

	public static var elements : dn.heaps.slib.SpriteLib;
	public static var aseIcons : dn.heaps.slib.SpriteLib;
	public static var elementsPixels : hxd.Pixels;

	public static function init() {
		fontPixel = hxd.Res.fonts.pixel_berry_xml.toFont();
		fontLight_tiny = hxd.Res.fonts.noto_sans_display_semicondensed_medium_12_xml.toFont();
		fontLight_regular = hxd.Res.fonts.noto_sans_display_semicondensed_medium_19_xml.toFont();
		fontLight_large = hxd.Res.fonts.noto_sans_display_semicondensed_light_30_xml.toFont();
		fontLight_title = hxd.Res.fonts.noto_sans_display_semicondensed_extralight_90_xml.toFont();

		elements = dn.heaps.assets.Aseprite.convertToSLib( Const.FPS, hxd.Res.atlas.appElements.toAseprite() );
		elementsPixels = elements.tile.getTexture().capturePixels();
		aseIcons = dn.heaps.assets.Aseprite.convertToSLib( Const.FPS, hxd.Res.atlas.icons.toAseprite() );
	}

	public static inline function getRegularFont() {
		return js.Browser.window.devicePixelRatio<=1 ? fontLight_tiny : fontLight_regular;
	}

	public static inline function getLargeFont() {
		return fontLight_large;
	}
}

#else

class Assets {
	// Enable XML format for bitmap fonts
	public static function enableXmlFonts() {
		hxd.res.Config.extensions.set("xml","hxd.res.BitmapFont");
	}
}

#end