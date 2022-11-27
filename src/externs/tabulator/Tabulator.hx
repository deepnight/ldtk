// Source: https://www.npmjs.com/package/tabulator-tables
package tabulator;

@:jsRequire("tabulator-tables")
extern class Tabulator {
	function new(element:String, options:Dynamic);

	public function on(eventName:String, cb:(args:Dynamic)->Void) : Void;

}

@:jsRequire("tabulator-tables")
extern class CellComponent {
	public function getValue() : Dynamic;
	public function getField() : Dynamic;
	public function getData() : Dynamic;
}
