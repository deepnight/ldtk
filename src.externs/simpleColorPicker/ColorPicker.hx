// Source: https://www.npmjs.com/package/simple-color-picker

package simpleColorPicker;

@:jsRequire("simple-color-picker")
extern class ColorPicker {
	public var isChoosing : Bool;

	public function new(options:Dynamic);

	public function appendTo( target : haxe.extern.EitherType<String,js.html.Element> ) : Void;
	public function remove() : Void;

	public function setColor( color : haxe.extern.EitherType<String,UInt> ) : Void;
	public function setSize(width:Float, height:Float) : Void;
	public function setBackgroundColor( color : haxe.extern.EitherType<String,UInt> ) : Void;
	public function setNoBackground() : Void;
	public function getColor() : haxe.extern.EitherType<String,UInt>;
	public function getHexNumber() : UInt;
	public function getHexString() : String;
	public function getRGB() : { r:Int, g:Int, b:Int };
	public function getHSV() : { h:Float, s:Float, v:Float };

	public function onChange( cb:(color:String)->Void ) : Void;
}


typedef ColorPickerOptions = {
	var ?el: js.html.HtmlElement;
	var ?color: haxe.extern.EitherType<String,UInt>;
}