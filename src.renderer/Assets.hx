#if !macro

class Assets {
	public static var fontPixelOutline : h2d.Font;
	public static var fontPixel : h2d.Font;
	public static var elements : dn.heaps.slib.SpriteLib;

	public static function init() {
		fontPixelOutline = hxd.Res.fonts.minecraftiaOutline.toFont();
		fontPixel = hxd.Res.fonts.pixel_berry_xml.toFont();

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