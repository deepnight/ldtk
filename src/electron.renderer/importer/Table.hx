package importer;

class Table {

	public function new() {}

	public function load(relPath:String, isSync=false):Map<String, Array<String>> {
		// if( isSync )
		// 	App.LOG.add("import", 'Syncing external enums: $relPath');
		// else
		// 	App.LOG.add("import", 'Importing external enums (new file): $relPath');

		var project = Editor.ME.project;
		var absPath = project.makeAbsoluteFilePath(relPath);
		var fileContent = NT.readFileString(absPath);
		var lines = fileContent.split("\n");

		var map = new Map<String, Array<String>>();

		var keys_ = lines[0];
		lines.remove(keys_);
		var keys:Array<String> = keys_.split(",");
		
		var pokemons = [];
		for (line in lines) {
			var values = line.split(",");
			pokemons.push(values);
		}

		for (i => key in keys) {
			map.set(key, new Array<String>());
			for (pokemon in pokemons){
				map[key].push(pokemon[i]);
			}
		}
		return map;
	}

}