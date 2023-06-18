package tabulator;

import tabulator.Tabulator.Module;

class CastleModule extends Module {
	static var moduleName = "castlemodule";
	static var moduleInitOrder = 10;

	public function new(table) {
		super(table);
    }
    
    public override function initialize() {

    }
}
