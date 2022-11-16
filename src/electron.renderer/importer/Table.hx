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

		// for (i => key in keys) {
		// 	map.set(key, new Array<String>());
		// 	for (row in data){
		// 		map[key].push(row[i]);
		// 	}
		// }
		project.defs.createTable(table_name, keys, data);
		return;
	}

}