enum FieldType {
	Standard(name:String);
	Unknown;
}

class XmlDocToMarkdown {
	public static function run(xmlPath) {
		Sys.println('Parsing $xmlPath...');
		var raw = sys.io.File.getContent(xmlPath);
		var xml = Xml.parse( raw );
		var xml = new haxe.xml.Access(xml);

		var md = [];

		// Parse types
		for(type in xml.node.haxe.elements) {
			if( type.att.path.indexOf("led.")<0 )
				continue;

			Sys.println('Found ${type.name}: ${type.att.path}');

			// Type name
			var name = type.att.path.substr(4);
			if( hasMeta(type,"display") )
				name = getMeta(type,"display");
			md.push('# $name');

			// Type desc
			if( type.hasNode.haxe_doc )
				md.push( type.node.haxe_doc.innerHTML );

			// Parse fields
			for(field in type.node.a.elements) {
				if( hasMeta(field,"hide") )
					continue;

				// Get type
				var type : FieldType =
					if( field.hasNode.x )
						Standard(field.node.x.att.path);
					else if( field.hasNode.c && field.node.c.att.path=="String" )
						Standard("String");
					else
						Unknown;

				Sys.println('  -> ${field.name}: $type');
				md.push('## `${field.name}` : **${printType(type)}**');
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


	/**
		Human readable type
	**/
	static function printType(t:FieldType) {
		return switch t {
			case Standard(name): name;
			case Unknown: "???";
		}
	}

}