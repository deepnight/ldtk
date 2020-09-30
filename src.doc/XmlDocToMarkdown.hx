enum FieldType {
	Standard(name:String);
	Arr(t:FieldType);
	Ref(display:String, typeName:String);
	Unknown;
}

class XmlDocToMarkdown {
	static var typeDisplayNames: Map<String,String>;

	public static function run(xmlPath) {
		typeDisplayNames = [];

		Sys.println('Parsing $xmlPath...');
		var raw = sys.io.File.getContent(xmlPath);
		var xml = Xml.parse( raw );
		var xml = new haxe.xml.Access(xml);

		// List types
		var allTypesXml = [];
		for(type in xml.node.haxe.elements) {
			if( type.att.path.indexOf("led.")<0 )
				continue;

			if( hasMeta(type,"hide") )
				continue;

			allTypesXml.push(type);
			typeDisplayNames.set(
				type.att.path,
				hasMeta(type,"display") ? getMeta(type,"display") : type.att.path
			);
		}


		// Parse types
		var md = [];
		for(type in allTypesXml) {
			Sys.println('Found ${type.name}: ${type.att.path}');

			// Type name
			md.push( makeAnchor(type.att.path) );
			md.push('# ${typeDisplayNames.get(type.att.path)}');

			// Type desc
			if( type.hasNode.haxe_doc )
				md.push( type.node.haxe_doc.innerHTML );

			// Parse fields
			if( !type.hasNode.a )
				continue;

			for(field in type.node.a.elements) {
				if( hasMeta(field,"hide") )
					continue;

				md.push( makeAnchor(type.att.path+" "+field.name) );

				// Get type
				var type = getType(field);

				// Field name & type
				Sys.println('  -> ${field.name}: $type');
				var name = field.name;
				if( hasMeta(field, "display") )
					name = getMeta(field,"display");

				md.push('## `$name` : **${printType(type)}**');

				// Type details
				if( hasMeta(field,"color") ) {
					if( type.equals(Standard("String")) )
						md.push('*Hexadecimal string using "#rrggbb" format*');
					else if( type.equals(Standard("UInt")) )
						md.push('*Hexadecimal integer using 0xrrggbb format*');
				}


				// Field desc
				if( field.hasNode.haxe_doc )
					md.push('${field.node.haxe_doc.innerHTML}');
			}
		}

		// Write markdown
		var fp = dn.FilePath.fromFile(xmlPath);
		fp.extension = "md";

		Sys.println('Writing markdown: ${fp.full}...');
		var fo = sys.io.File.write(fp.full, false);
		fo.writeString(md.join("\n\n"));
		fo.close();
	}


	/**
		Return TRUE if field has specified meta data
	**/
	static function hasMeta(xml:haxe.xml.Access, name:String) {
		if( !xml.hasNode.meta || !xml.node.meta.hasNode.m )
			return false;

		for(m in xml.node.meta.nodes.m )
			if( m.att.n == name )
				return true;

		return false;
	}


	/**
		Get meta data of a field
	**/
	static function getMeta(xml:haxe.xml.Access, name:String) {
		if( !hasMeta(xml,name) )
			return null;

		for(m in xml.node.meta.nodes.m )
			if( m.att.n == name ) {
				var v = m.node.e.innerHTML;
				if( v.charAt(0)=="\"" )
					return v.substring(1, v.length-1);
				else
					return v;
			}

		throw "Malformed meta?";
	}

	static function getType(fieldXml:haxe.xml.Access) : FieldType {
		return
			if( fieldXml.hasNode.x )
				Standard(fieldXml.node.x.att.path);
			else if( fieldXml.hasNode.d )
				Standard("Anonymous structure");
			else if( fieldXml.hasNode.t ) {
				var name = fieldXml.node.t.att.path;
				Ref( typeDisplayNames.get(name), name );
			}
			else if( fieldXml.hasNode.c ) {
				switch fieldXml.node.c.att.path {
					case "String": Standard("String");
					case "Array": Arr( getType(fieldXml.node.c) );
					case _: Unknown;
				}
			}
			else
				Unknown;
	}

	/**
		Human readable type
	**/
	static function printType(t:FieldType) {
		return switch t {
			case Standard(name):
				switch name {
					case "UInt": "Unsigned integer";
					case _: name;
				}
			case Ref(display, name): '[$display](#${anchorId(name)})';
			case Arr(t): 'Array of ${printType(t)}';
			case Unknown: "???";
		}
	}


	/**
		Create an anchor name
	**/
	static function anchorId(str:String) {
		var r = ~/[^a-z0-9_]/gi;
		str = StringTools.replace(str,"\t"," ");
		str = StringTools.trim(str);
		return r.replace(str,"-");
	}

	static function makeAnchor(str:String) {
		return '<a id="${anchorId(str)}" name="${anchorId(str)}"></a>';
	}

}