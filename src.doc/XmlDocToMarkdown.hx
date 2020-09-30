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
			var name = type.att.path.substr(4);
			md.push('# $name');
			md.push( type.node.haxe_doc.innerHTML );

			// Parse fields
			for(field in type.node.a.elements) {
				if( field.hasNode.meta && field.node.meta.hasNode.m && field.node.meta.node.m.att.n==":hide")
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
				md.push('## `${field.name}` : **${getTypeStr(type)}**');
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

	static function getTypeStr(t:FieldType) {
		return switch t {
			case Standard(name): name;
			case Unknown: "???";
		}
	}

}