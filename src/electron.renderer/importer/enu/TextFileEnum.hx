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

			var enumId = StringTools.trim( line.split(":")[0] );
			var values = [];
			var rawValues = StringTools.trim( line.split(":")[1] );
			if( rawValues.length>0 ) {
				var valueSep = null;
				for(s in [",", ";", " "])
					if( rawValues.indexOf(s)>=0 ) {
						valueSep = s;
						break;
					}
				if( valueSep==null )
					continue;
				values = rawValues.split(valueSep).map( v->{
					valueId: StringTools.trim(v),
					data: { color:null },
				});
			}
			parseds.push({
				enumId: enumId,
				values: values,
			});
		}

		return parseds;
	}
}