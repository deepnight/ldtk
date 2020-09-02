#if !macro

class Assets {
	public static var fontPixelOutline : h2d.Font;
	public static var fontPixel : h2d.Font;

	public static function init() {
		fontPixelOutline = hxd.Res.fonts.minecraftiaOutline.toFont();
		fontPixel = hxd.Res.fonts.pixel_berry_xml.toFont();
		// fontPixel = hxd.Res.fonts.pixel_unicode_regular_12_xml.toFont();
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