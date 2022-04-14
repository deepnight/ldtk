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
				values: [],
			}

			// Parse values
			var rawValues = StringTools.trim( line.split(":")[1] );
			if( rawValues.length>0 ) {
				// Guess separator
				var valueSep = null;
				for(s in [",", ";", " "])
					if( rawValues.indexOf(s)>=0 ) {
						valueSep = s;
						break;
					}
				if( valueSep==null )
					continue;

				// Split values
				for( raw in rawValues.split(valueSep) ) {
					raw = StringTools.trim(raw);
					if( raw.length==0 )
						continue;
					parsed.values.push({
						valueId: raw,
						data: { color:null },
					});
				}
			}
			parseds.push(parsed);
		}

		return parseds;
	}
}