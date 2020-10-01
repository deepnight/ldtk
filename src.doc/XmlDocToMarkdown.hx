enum Field {
	Basic(name:String);
	Arr(t:Field);
	Obj(fields:Array<{ name:String, type:Field, doc:Null<String> }>);
	Ref(display:String, typeName:String);
	Dyn;
	Unknown;
}

class XmlDocToMarkdown {
	static var typeDisplayNames: Map<String,{ section:Null<String>, name:String }>;

	public static function run(xmlPath:String, ?mdPath:String, deleteXml=false) {
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

			var displayName = type.att.path;
			if( hasMeta(type,"display") )
				displayName = getMeta(type,"display");

			typeDisplayNames.set(type.att.path, {
				name: displayName,
				section: getMeta(type,"section"),
			});
		}

		// Sort types
		allTypesXml.sort( (a,b)->{
			var a = typeDisplayNames.get(a.att.path);
			var b = typeDisplayNames.get(b.att.path);
			if( a.section!=null && b.section==null ) return 1;
			if( a.section==null && b.section!=null ) return -1;
			if( a.section==null && b.section==null )
				return Reflect.compare(a.name, b.name);
			else
				return Reflect.compare(a.section, b.section);
		});

		var toc = [];

		// Parse types
		var md = [];
		for(type in allTypesXml) {
			var depth = 0;
			Sys.println('Found ${type.name}: ${type.att.path}');

			if( hasMeta(type,"section") ) {
				var s = getMeta(type,"section");
				depth = s.split(".").length-1;
			}

			// Type name
			md.push( makeAnchor(type.att.path) );
			md.push("&nbsp;");
			var display = typeDisplayNames.get(type.att.path);
			// if( display.section!=null )
			// 	md.push('${makeMdTitlePrefix(depth)} ${display.section} - ${display.name}');
			// else
				md.push('${makeMdTitlePrefix(depth)} ${display.name}');

			toc.push({
				depth: depth,
				name: display.name,
				anchor: anchorId(type.att.path),
			});

			// Type desc
			if( type.hasNode.haxe_doc )
				md.push( type.node.haxe_doc.innerHTML );

			if( !type.hasNode.a )
				continue;


			// List fields
			var allFields = [];
			for(field in type.node.a.elements) {
				if( hasMeta(field,"hide") )
					continue;
				allFields.push({
					displayName: field.name,
					xml: field,
				});
			}
			allFields.sort( (a,b)->Reflect.compare(a.displayName, b.displayName) );


			// Parse fields
			for(field in allFields) {
				md.push( makeAnchor(type.att.path+" "+field.xml.name) );

				// Get type
				var type = getType(field.xml);

				// Field name & type
				Sys.println('  -> ${field.xml.name}: $type');
				var name = field.xml.name;
				if( hasMeta(field.xml, "display") )
					name = getMeta(field.xml,"display");

				md.push(' - ${makeMdTitlePrefix(depth+1)} `$name` : **${printType(type)}**');

				// "Only for" limitation
				if( hasMeta(field.xml,"only") )
					md.push('    **Only available for ${getMeta(field.xml,"only")}**');

				// Color
				if( hasMeta(field.xml,"color") ) {
					if( type.equals(Basic("String")) )
						md.push('    *Hexadecimal string using "#rrggbb" format*');
					else if( type.equals(Basic("UInt")) )
						md.push('    *Hexadecimal integer using 0xrrggbb format*');
				}

				// Helpers
				// if( field.xml.name.indexOf("__")==0 )
				// 	md.push(" - *This field only exists to facilitate JSON parsing.*");

				// Field desc
				if( field.xml.hasNode.haxe_doc )
					md.push('    ${field.xml.node.haxe_doc.innerHTML}');

				// Anonymous object
				var objMd = getInlineObjectMd(type);
				if( objMd.length>0 )
					md = md.concat(objMd);

			}
		}


		// Table of content
		var tocMd = ["# Table of content"];
		for(e in toc) {
			var indent = " -";
			for(i in 0...e.depth)
				indent = "  "+indent;
			tocMd.push('$indent [${e.name}](#${e.anchor})');
		}
		md = tocMd.concat(md);


		// Write markdown file
		if( mdPath==null ) {
			var fp = dn.FilePath.fromFile(xmlPath);
			fp.extension = "md";
			mdPath = fp.full;
		}

		Sys.println('Writing markdown: ${mdPath}...');
		var fo = sys.io.File.write(mdPath, false);
		fo.writeString(md.join("\n\n"));
		fo.close();

		// Cleanup
		if( deleteXml )
			sys.FileSystem.deleteFile(xmlPath);
	}


	/**
		Return the markdown of an anonymous object
	**/
	static function getInlineObjectMd(type:Field, depth=0) {
		switch type {

		case Arr(Obj(fields)), Obj(fields):
			var md = [];

			if( depth==0 )
				if( type.getIndex()==Arr(null).getIndex() )
					md.push("    This array contains objects with all the following fields:");
				else
					md.push("    This object contains all the following fields:");
			depth++;

			for(f in fields) {
				md.push('${addIndent(" -",1)} `${f.name}` : **${printType(f.type)}**${ f.doc==null ? "" : " -- "+f.doc}');
				switch f.type {
					case Arr(Obj(fields)), Obj(fields):
						md = md.concat( getInlineObjectMd(f.type, depth) );

					case _:
				}
			}

			return md;

		case _:
			return [];
		}

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

	static function getType(fieldXml:haxe.xml.Access) : Field {
		return
			if( fieldXml.hasNode.x )
				Basic(fieldXml.node.x.att.path);
			else if( fieldXml.hasNode.d )
				Dyn;
			else if( fieldXml.hasNode.t ) {
				var name = fieldXml.node.t.att.path;
				Ref( typeDisplayNames.get(name).name, name );
			}
			else if( fieldXml.hasNode.a ) {
				// List fields
				var fields = [];
				for(n in fieldXml.node.a.elements) {
					var doc = n.hasNode.haxe_doc ? n.node.haxe_doc.innerHTML : null;
					fields.push({ name:n.name, type:getType(n), doc:doc });
				}
				// Sort
				var basic = Basic(null).getIndex();
				fields.sort( (a,b)->{
					if( a.type.getIndex()==basic && b.type.getIndex()!=basic ) return -1;
					if( a.type.getIndex()!=basic && b.type.getIndex()==basic ) return 1;
					return Reflect.compare(a.name, b.name);
				});
				Obj(fields);
			}
			else if( fieldXml.hasNode.c ) {
				switch fieldXml.node.c.att.path {
					case "String": Basic("String");
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
	static function printType(t:Field) {
		return switch t {
			case Basic(name):
				switch name {
					case "UInt": "Unsigned integer";
					case _: name;
				}
			case Ref(display, name): '[$display](#${anchorId(name)})';
			case Arr(t): 'Array of ${printType(t)}';
			case Obj(fields): "Object";
			case Dyn: "Dynamic (anything)";
			case Unknown: "???";
		}
	}


	static function makeMdTitlePrefix(depth:Int) {
		var out = "";
		for(i in 0...depth+1)
			out+="#";
		return out;
	}

	static function addIndent(char:String, depth:Int) {
		var out = "";
		for(i in 0...depth+1)
			out+=" ";
		return out + char;
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

	/**
		Create an anchor tag
	**/
	static function makeAnchor(str:String) {
		return '<a id="${anchorId(str)}" name="${anchorId(str)}"></a>';
	}

}