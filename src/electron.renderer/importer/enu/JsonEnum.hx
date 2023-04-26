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
								tilesetUid: null,
								values: arr.map( v->{
									valueId: v,
									data: { color:null, tileRect:null },
								}),
							});

						case _:
							continue;
					}

				case TClass(String):
					var rawValues : String = e;
					var values = parseValuesFromString(rawValues);
					var parsedEnum : ParsedExternalEnum = {
						enumId: k,
						tilesetUid: null,
						values: values.map( v->{ valueId:v, data:{ color:null, tileRect:null } }),
					}
					parseds.push( parsedEnum );

				case _:
					continue;
			}
		}
		return parseds;
	}
}