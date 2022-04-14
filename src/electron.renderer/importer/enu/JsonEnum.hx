package importer.enu;

class JsonEnum extends importer.ExternalEnum {

	public function new() {
		super();
	}

	override function parse(fileContent:String) : Array<ParsedExternalEnum> {
		super.parse(fileContent);

		var json = try haxe.Json.parse(fileContent) catch(_) null;
		if( json==null )
			return [];

		var parseds : Array<ParsedExternalEnum> = [];
		for( k in Reflect.fields(json) ) {
			var e = Reflect.field(json, k);
			switch Type.typeof(e) {
				case TClass(Array):
					var arr : Array<Dynamic> = cast e;
					if( arr.length==0 )
						continue;
					switch Type.typeof(arr[0]) {
						case TClass(String):
							parseds.push({
								enumId: k,
								values: arr.map( v->{
									valueId: v,
									data: { color:null },
								}),
							});

						case _:
							continue;
					}

				case TClass(String):
					var rawValues : String = e;
					var sep = rawValues.indexOf(",")>=0 ? ","
						: rawValues.indexOf(";")>=0 ? ";"
						: " ";

					var parsedEnum : ParsedExternalEnum = {
						enumId: k,
						values: [],
					}
					for(raw in rawValues.split(sep)) {
						raw = StringTools.trim(raw);
						if( raw.length>0 )
							parsedEnum.values.push({
								valueId: raw,
								data: { color:null },
							});
					}
					parseds.push( parsedEnum );

				case _:
					continue;
			}
		}
		return parseds;
	}
}