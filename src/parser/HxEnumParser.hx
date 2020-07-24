package parser;

class HxEnumParser {
	public static function run(fileContent:String) : Array<ParsedExternalEnum> {
		// Trim comments
		var lineCommentReg = ~/^([^\/\n]*)(\/\/.*)$/gm;
		fileContent = lineCommentReg.replace(fileContent,"$1");
		var multilineCommentReg = ~/(\/\*[\s\S]*?\*\/)/gm;
		fileContent = multilineCommentReg.replace(fileContent,"");

		// Any enum?
		var enumBlocksReg = ~/^[ \t]*enum[ \t]+([a-z0-9_]+)[ \t]*{/gim;
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
						values: values,
					});
				}
			}


			fileContent = enumBlocksReg.matchedRight();
		}
		return parseds;
	}
}