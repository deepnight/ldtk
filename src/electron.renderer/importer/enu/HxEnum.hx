package importer.enu;

class HxEnum extends importer.ExternalEnum {

	public function new() {
		super();
	}

	override function parse(fileContent:String) : Array<ParsedExternalEnum> {
		super.parse(fileContent);

		// Trim comments
		var lineCommentReg = ~/^([^\/\n]*)(\/\/.*)$/gm;
		fileContent = lineCommentReg.replace(fileContent,"$1");
		var multilineCommentReg = ~/(\/\*[\s\S]*?\*\/)/gm;
		fileContent = multilineCommentReg.replace(fileContent,"");

		// Any enum?
		var enumBlocksReg = ~/^\s*enum\s+([a-z0-9_]+)\s*{/gim;
		if( !enumBlocksReg.match(fileContent) ) {
			N.error("Couldn't find any simple Enum in this source fileContent.");
			return [];
		}

		// Search enum blocks
		var parseds : Array<ParsedExternalEnum> = [];
		while( enumBlocksReg.match(fileContent) ) {
			var enumId = enumBlocksReg.matched(1);

			// Extract values block
			var brackets = 1;
			var pos = enumBlocksReg.matchedPos().pos + enumBlocksReg.matchedPos().len;
			var start = pos;
			while( pos < fileContent.length && brackets>=1 ) {
				if( fileContent.charAt(pos)=="{" )
					brackets++;
				else if( fileContent.charAt(pos)=="}" )
					brackets--;
				pos++;
			}
			var rawValues = fileContent.substring(start,pos-1);

			// Checks presence of unsupported Parametered values
			var paramEnumReg = ~/([A-Z][A-Za-z0-9_]*)[ \t]*\(/gm;
			if( !paramEnumReg.match(rawValues) ) {
				// This enum only contains unparametered values
				var enumValuesReg = ~/([A-Z][A-Za-z0-9_]*)[ \t]*;/gm;
				var values = [];
				while( enumValuesReg.match(rawValues) ) {
					values.push( enumValuesReg.matched(1) );
					rawValues = enumValuesReg.matchedRight();
				}
				if( values.length>0 ) {
					// Success!
					parseds.push({
						enumId: enumId,
						tilesetUid: null,
						values: values.map( id->{ valueId:id, data:{ color:null, tileRect:null } }),
					});
				}
			}


			fileContent = enumBlocksReg.matchedRight();
		}
		return parseds;
	}
}