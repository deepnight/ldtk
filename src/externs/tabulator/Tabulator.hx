// Source: https://www.npmjs.com/package/tabulator-tables
package tabulator;
import js.html.Element;
import haxe.extern.EitherType;

@:jsRequire("tabulator-tables")
extern class Tabulator {
	function new(element:EitherType<String, js.html.Element>, options:Dynamic);

	public function on(eventName:String, cb:(e:Dynamic, cell:Dynamic) -> Void):Void;
}

@:jsRequire("tabulator-tables")
extern class CellComponent {
	public function getValue():Dynamic;
	public function getField():Dynamic;
	public function getData():Dynamic;
}
