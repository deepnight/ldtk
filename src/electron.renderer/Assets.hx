#if !macro

class Assets {
	public static var fontLight_small : h2d.Font;
	public static var fontLight_medium : h2d.Font;
	public static var fontLight_large : h2d.Font;
	public static var fontLight_xlarge : h2d.Font;
	public static var fontPixel : h2d.Font;
	public static var fontPixelOutline : h2d.Font;

	public static var elements : dn.heaps.slib.SpriteLib;

	public static function init() {
		fontPixelOutline = hxd.Res.fonts.minecraftiaOutline.toFont();
		fontPixel = hxd.Res.fonts.pixel_berry_xml.toFont();
		fontLight_small = hxd.Res.fonts.robotoLight24.toFont();
		fontLight_medium = hxd.Res.fonts.robotoLight36.toFont();
		fontLight_large = hxd.Res.fonts.robotoLight48.toFont();
		fontLight_xlarge = hxd.Res.fonts.robotoLight72.toFont();

		elements = dn.heaps.assets.Atlas.load("appElements.atlas");
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