package importer;
import thx.csv.Csv;

class Table {

	public function new() {}

	public function load(relPath:String, isSync=false) {
		// if( isSync )
		// 	App.LOG.add("import", 'Syncing external enums: $relPath');
		// else
		// 	App.LOG.add("import", 'Importing external enums (new file): $relPath');

		var project = Editor.ME.project;
		var absPath = project.makeAbsoluteFilePath(relPath);
		var fileContent = NT.readFileString(absPath);
		var table_name = absPath.split("/").pop();
		
		var data:Array<Array<Dynamic>> = Csv.decode(fileContent);

		var keys:Array<String> = data[0].map(Std.string);
		data.shift(); // Remove keys from the array
		
		for (i => key in keys) {
			// Check if all of the values in this column can be converted into Int
			var int:Bool = true;
			for (row in data) {
				if (Std.parseInt(row[i]) == null) {
					int = false;
					break;
				}
			}
			// If yes, convert
			if (int) {
				for (row in data) {
					row[i] = Std.parseInt(row[i]);
				}
			}

			// Check if all of the values in this column can be converted into Float
			var float:Bool = true;
			for (row in data) {
				if (Math.isNaN(Std.parseFloat(row[i]))) {
					float = false;
					break;
				}
			}
			// If yes, convert
			if (float) {
				for (row in data) {
					row[i] = Std.parseFloat(row[i]);
				}
			}
		}

		project.defs.createTable(table_name, keys, data);
		return;
	}

}