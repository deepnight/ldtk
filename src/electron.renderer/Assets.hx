#if !macro

class Assets {
	public static var fontLight_tiny : h2d.Font;
	public static var fontLight_small : h2d.Font;
	public static var fontLight_medium : h2d.Font;
	public static var fontLight_large : h2d.Font;
	public static var fontLight_xlarge : h2d.Font;
	public static var fontPixel : h2d.Font;
	public static var fontPixelOutline : h2d.Font;

	public static var elements : dn.heaps.slib.SpriteLib;
	public static var elementsPixels : hxd.Pixels;

	public static function init() {
		fontPixelOutline = hxd.Res.fonts.minecraftiaOutline.toFont();
		fontPixel = hxd.Res.fonts.pixel_berry_xml.toFont();
		fontLight_tiny = hxd.Res.fonts.roboto24.toFont();
		fontLight_small = hxd.Res.fonts.roboto30.toFont();
		fontLight_medium = hxd.Res.fonts.roboto36.toFont();
		fontLight_large = hxd.Res.fonts.roboto48.toFont();
		fontLight_xlarge = hxd.Res.fonts.roboto72.toFont();

		elements = dn.heaps.assets.Atlas.load("appElements.atlas");
		elementsPixels = elements.tile.getTexture().capturePixels();

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