package importer.enu;

class TextFileEnum extends importer.ExternalEnum {

	public function new() {
		super();
	}

	override function parse(fileContent:String) : Array<ParsedExternalEnum> {
		super.parse(fileContent);

		var parseds : Array<ParsedExternalEnum> = [];
		var lines = fileContent.split("\n");
		for(line in lines) {
			if( line.indexOf(":")<0 && StringTools.trim(line).length>0 )
				continue;

			var parsed : ParsedExternalEnum = {
				enumId: StringTools.trim( line.split(":")[0] ),
				tilesetUid: null,
				values: [],
			}

			// Parse values
			var values = parseValuesFromString( line.split(":")[1] );
			for(v in values)
				parsed.values.push({
					valueId: v,
					data: { color:null, tileRect:null },
				});
			parseds.push(parsed);
		}

		return parseds;
	}
}