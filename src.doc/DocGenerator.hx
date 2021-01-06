/**
	Json Documentation and Schema generator

	Useful links:
	- QuickType: https://app.quicktype.io/
	- JsonSchema doc: https://json-schema.org/understanding-json-schema/index.html
	- Test JsonSchema: https://www.jsonschemavalidator.net/
**/

import haxe.Json;
using StringTools;


enum FieldType {
	Nullable(f:FieldType);
	Basic(name:String);
	Enu(name:String);
	Arr(t:FieldType);
	Obj(fields:Array<FieldInfos>);
	Ref(display:String, typeName:String);
	Dyn;
	Unknown;
}

typedef FieldInfos = {
	var xml: haxe.xml.Access;
	var subFields: Array<FieldInfos>;

	var displayName: String;
	var type: FieldType;
	var descMd: Array<String>;

	var only: Null<String>;
	var hasVersion: Bool;
	var isColor: Bool;
	var isInternal: Bool;
}

typedef GlobalType = {
	var rawName : String;
	var displayName : String;
	var xml : haxe.xml.Access;
	var section : String;
}


typedef SchemaType = {
	var ?title: String;
	var ?type: Array<String>;
	var ?description: String;
	var ?required: Array<String>;
	var ?properties: Map<String, SchemaType>;
	var ?additionalProperties: Bool;
	var ?items: SchemaType;
	var ?enum__: Array<String>;
	var ?ref__: String;
}


class DocGenerator {
	#if macro
	static var SCHEMA_URL = "https://ldtk.io/files/JSON_SCHEMA.json";

	static var allTypes: Array<GlobalType>;
	static var allEnums : Map<String, Array<String>>;
	static var verbose = false;
	static var appVersion = new dn.Version();

	/**
		Generate Markdown doc and Json schema
	**/
	public static function run(className:String, xmlPath:String, ?mdPath:String, ?jsonPath:String, deleteXml=false) {
		allTypes = [];
		allEnums = [];

		// Read app version from "package.json"
		haxe.macro.Context.registerModuleDependency("DocGenerator", "app/package.json");
		var raw = sys.io.File.getContent("app/package.json");
		var versionReg = ~/"version"[ \t]*:[ \t]*"(.*)"/gim;
		versionReg.match(raw);
		appVersion.set( versionReg.matched(1) );
		Sys.println('App version is $appVersion...');

		// Read XML file
		Sys.println("");
		Sys.println('Parsing $xmlPath...');
		haxe.macro.Context.registerModuleDependency("DocGenerator", xmlPath);
		var raw = sys.io.File.getContent(xmlPath);
		var xml = Xml.parse( raw );
		var xml = new haxe.xml.Access(xml);

		// List types
		for(type in xml.node.haxe.elements) {
			if( type.att.file.indexOf(className)<0 )
				continue;

			if( hasMeta(type,"hide") )
				continue;

			var displayName = type.att.path;
			if( hasMeta(type,"display") )
				displayName = getMeta(type,"display");

			if( type.name=="enum") {
				// Enum
				var enumValues = [];
				for(n in type.elements)
					switch n.name {
						case "meta", "haxe_doc":
						case _: enumValues.push(n.name);
					}

				allEnums.set(type.att.path, enumValues);
			}
			else {
				// Typedef
				allTypes.push({
					xml: type,
					rawName: type.att.path,
					displayName: displayName,
					section: hasMeta(type,"section") ? getMeta(type,"section") : "",
				});
			}

			Sys.println('Found ${type.name}: $displayName');
		}
		Sys.println("");

		// Sort types
		allTypes.sort( (a,b)->{
			// var a = displayNames.get(a.att.path);
			// var b = displayNames.get(b.att.path);
			if( a.section!=null && b.section==null ) return 1;
			if( a.section==null && b.section!=null ) return -1;
			if( a.section==null && b.section==null )
				return Reflect.compare(a.displayName, b.displayName);
			else
				return Reflect.compare(a.section, b.section);
		});

		// Markdown doc output
		Sys.println("Generating Markdown doc");
		genMarkdownDoc(xml, className, xmlPath, mdPath);
		Sys.println("");

		// Json schema output
		Sys.println("Generating JSON schema");
		genJsonSchema(xml, className, xmlPath, jsonPath);

		// Cleanup
		if( deleteXml ) {
			Sys.println("Deleting XML file");
			sys.FileSystem.deleteFile(xmlPath);
		}

		Sys.println("");
		Sys.println('Done!');
		Sys.println('');
	}



	/**
		Build doc
	**/
	static function genMarkdownDoc(xml:haxe.xml.Access, className:String, xmlPath:String, ?mdPath:String) {
		// Print types
		var toc = [];
		var md = [];
		for(type in allTypes) {
			md.push("");
			var depth = 0;

			// Anchor
			md.push( getAnchorHtml(type.xml.att.path) );

			// Type title
			var title = '${type.displayName} ${versionBadge(type.xml)}';
			if( type.section!="" )
				title = type.section+". "+title;
			md.push('## $title');

			// Add to ToC
			toc.push({
				name: type.displayName,
				anchor: anchorId(type.xml.att.path),
				depth: type.section.split(".").length,
			});

			// No field informations for this type
			if( !type.xml.hasNode.a ) {
				md.push('Sorry this type has no documentation yet.');
				continue;
			}


			// List fields
			var allFields = getFieldsInfos(type.xml.node.a);

			// Table header
			var header = ["Value","Type","Description"];
			md.push( header.join(" | ") );
			var line = [ for(i in 0...header.length) "--" ];
			md.push( line.join(" | ") );


			// List fields
			for(f in allFields) {
				var tableCols = [];
				var subRows = [];

				if( verbose )
					Sys.println('  -> ${f.displayName} : ${getTypeMd(f.type)}');

				// Name
				var cell = [ '`${f.displayName}`' ];
				if( f.only!=null )
					cell.push('<sup class="only">Only *${f.only}*</sup>');
				if( f.isInternal )
					cell.push('<sup class="internal">*Internal editor data*</sup>');

				if( f.hasVersion )
					cell.push( versionBadge(f.xml) );

				tableCols.push( cell.join("<br/>") );

				// Type
				var type = '${getTypeMd(f.type)}';
				if( f.isColor )
					type+="<br/>"+getColorInfosMd(f);
				type = StringTools.replace(type," ","&nbsp;");
				tableCols.push(type);

				// Desc
				var cell = f.descMd;

				if( f.subFields.length>0 ) {
					cell.push("This object contains the following fields:");
					cell.push( getSubFieldsHtml( f.subFields ) );
				}

				tableCols.push( cell.join("<br/> ") );

				md.push( tableCols.join(" | "));
				for(row in subRows)
					md.push("| "+row+" |");
			}
		}




		// Header
		var headerMd = [
			'# LDtk Json structure (version $appVersion)',
			'',
			'Json schema: $SCHEMA_URL',
			'',
			'## Table of contents',
		];

		// Table of content
		for(e in toc) {
			var indent = " -";
			for(i in 0...e.depth)
				indent = "  "+indent;
			headerMd.push('$indent [${e.name}](#${e.anchor})');
		}
		md = headerMd.concat(md);


		// Write markdown file
		if( mdPath==null ) {
			var fp = dn.FilePath.fromFile(xmlPath);
			fp.extension = "md";
			mdPath = fp.full;
		}

		Sys.println(' > Writing: ${mdPath}...');
		var fo = sys.io.File.write(mdPath, false);
		fo.writeString(md.join("\n"));
		fo.close();
	}



	/**
		Build Json schema
	**/
	static function genJsonSchema(xml:haxe.xml.Access, className:String, xmlPath:String, ?jsonPath:String) {
		// Prepare Json structure
		var json = {
			LdtkJsonRoot: null,
			otherTypes: new Map<String,Dynamic>(),
		};


		for(type in allTypes) {

			// No field informations for this type?
			if( !type.xml.hasNode.a )
				continue;

			// Init json type
			var typeName = type.rawName.substr( type.rawName.lastIndexOf(".")+1 ).replace("Json","");
			var typeJson : SchemaType = {}
			typeJson.type = ["object"];
			typeJson.properties = [];
			typeJson.required = [];
			typeJson.title = type.displayName;


			// List fields
			for(f in getFieldsInfos(type.xml.node.a)) {
				var st = getSchemaType(f.type);
				st.description = f.descMd.join('\n');

				// Detect required fields
				if( st.type!=null ) {
					var req = true;
					for( t in st.type )
						if( t=="null" ) {
							req = false;
							break;
						}
					if( req )
						typeJson.required.push(f.displayName);
				}

				typeJson.properties.set(f.displayName, st);
			}

			// Store type
			if( typeName=="Project" )
				json.LdtkJsonRoot = typeJson;
			else {
				typeJson.additionalProperties = false;
				json.otherTypes.set(typeName, typeJson);
			}
		}

		// Default output file name
		if( jsonPath==null ) {
			var fp = dn.FilePath.fromFile(xmlPath);
			fp.extension = "md";
			jsonPath = fp.full;
		}

		// Write Json file
		var header = {
			"$schema": "https://json-schema.org/draft-07/schema#",
			title: "LDtk JSON schema v"+appVersion.numbers,
			description: "This file is a JSON schema of files created by LDtk level editor (https://ldtk.io).",
			"$ref" : "#/LdtkJsonRoot",
		}
		Sys.println(' > Writing: ${jsonPath}...');
		var fo = sys.io.File.write(jsonPath, false);
		var jsonStr = dn.JsonPretty.stringify(json, Full, header, true);
		jsonStr = jsonStr.replace('"ref__"', "\"$ref\"");
		jsonStr = jsonStr.replace('"enum__"', '"enum"');
		fo.writeString(jsonStr);
		fo.close();
	}


	static function getColorInfosMd(f:FieldInfos) : String {
		return '<small class="color">*' + ( switch f.type {
			case Nullable(Basic("String")), Basic("String"):
				'Hex color "#rrggbb"';

			case Nullable(Basic("UInt")), Basic("UInt"), Nullable(Basic("Int")), Basic("Int"):
				'Hex color 0xrrggbb';

			case _:
				'???';
		} ) + '*</small>';
	}


	static function getSubFieldsHtml(fields:Array<FieldInfos>) {
		var list = [];
		for(f in fields) {
			var li = [];
			// Name
			li.push('**`${f.displayName}`**');

			// Type
			li.push('**(${getTypeMd(f.type)}**)');

			// Version badges
			if( f.hasVersion )
				li.push( versionBadge(f.xml) );

			// Color
			if( f.isColor )
				li.push( getColorInfosMd(f) );

			// Desc
			if( f.descMd.length>0 ) {
				li.push(":");
				for( descLine in f.descMd )
					li.push('*$descLine*');
			}

			// Sub fields
			if( f.subFields.length>0 )
				li.push( getSubFieldsHtml(f.subFields) );

			list.push( li.join(" ") );
		}

		return "<ul><li>" + list.join("</li><li>") + "</li></ul>";
	}



	/**
		Extract all field informations
	**/
	static function getFieldsInfos(fieldsXml:haxe.xml.Access) : Array<FieldInfos> {
		var allFields : Array<FieldInfos> = [];
		for(fieldXml in fieldsXml.elements) {
			if( hasMeta(fieldXml,"hide") )
				continue;

			var displayName = hasMeta(fieldXml, "display") ? getMeta(fieldXml, "display") : fieldXml.name;

			var descMd = [];
			if( fieldXml.hasNode.haxe_doc ) {
				var html = fieldXml.node.haxe_doc.innerHTML;
				html = StringTools.replace(html, "<![CDATA[", "");
				html = StringTools.replace(html, "]]>", "");
				html = StringTools.replace(html, "\n", "<br/>");
				descMd.push(html);
			}

			var type = getFieldType(fieldXml);
			var subFields = switch type {
				case Obj(f): f;
				case Arr(Obj(f)): f;
				case Nullable( Obj(f) ): f;
				case Nullable( Arr(Obj(f)) ): f;
				case _: [];
			}

			switch type {
				case Enu(name): descMd.push("Possible values: `"+allEnums.get(name).join("`, `")+"`");
				case _:
			}

			allFields.push({
				xml: fieldXml,
				displayName: displayName,
				type: type,
				subFields: subFields,

				only: getMeta(fieldXml, "only"),
				hasVersion: hasMeta(fieldXml, "changed") || hasMeta(fieldXml, "added"),
				descMd: descMd,
				isColor: hasMeta(fieldXml, "color"),
				isInternal: hasMeta(fieldXml, "internal"),
			});
		}
		allFields.sort( (a,b)->Reflect.compare(a.displayName, b.displayName) );

		return allFields;
	}


	/**
		Create a version info badge ("added/changed" meta)
	**/
	static function versionBadge(xml:haxe.xml.Access) {
		var badges = [];

		if( hasMeta(xml,"added") ) {
			var version = getMeta(xml,"added");
			badges.push( badge("Added", version, appVersion.sameMajorAndMinor(version) ? "green" : "gray" ) );
		}

		if( hasMeta(xml,"changed") ) {
			var version = getMeta(xml,"changed");
			badges.push( badge("Changed", version, appVersion.sameMajorAndMinor(version) ? "green" : "gray" ) );

		}

		return " "+badges.join(" ")+" ";
	}


	/**
		Create a badge markdown
	**/
	static function badge(name:String, value:String, ?color:String) {
		return '![Generic badge](https://img.shields.io/badge/${name}_${value}-${color}.svg)';
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
		Return the type Enum of a specific field XML
	**/
	static function getFieldType(fieldXml:haxe.xml.Access) : FieldType {
		return
			if( fieldXml.hasNode.x ) {
				if( fieldXml.node.x.att.path=="Null" )
					Nullable( getFieldType(fieldXml.node.x) );
				else
					Basic(fieldXml.node.x.att.path);
			}
			else if( fieldXml.hasNode.d )
				Dyn;
			else if( fieldXml.hasNode.t ) {
				var name = fieldXml.node.t.att.path;
				var typeInfos = allTypes.filter( (t)->t.rawName==name )[0];
				var dispName = typeInfos==null ? name : typeInfos.displayName;
				Ref( dispName, name );
			}
			else if( fieldXml.hasNode.e ) {
				Enu(fieldXml.node.e.att.path);
			}
			else if( fieldXml.hasNode.a ) {
				Obj( getFieldsInfos(fieldXml.node.a) );
			}
			else if( fieldXml.hasNode.c ) {
				switch fieldXml.node.c.att.path {
					case "String": Basic("String");
					case "Array": Arr( getFieldType(fieldXml.node.c) );
					case _: Unknown;
				}
			}
			else
				Unknown;
	}

	/**
		Human readable type
	**/
	static function getTypeMd(t:FieldType) {
		var str = switch t {
			case Nullable(f): getTypeMd(f)+" *(can be `null`)*";
			case Basic(name):
				switch name {
					case "UInt": "Unsigned integer";
					case _: name;
				}
			case Enu(name): 'Enum';
			case Ref(display, name): '[$display](#${anchorId(name)})';
			case Arr(t): 'Array of ${getTypeMd(t)}';
			case Obj(fields): "Object";
			case Dyn: "Dynamic (anything)";
			case Unknown: "???";
		}
		return str;
	}

	static function getSchemaType(t:FieldType): SchemaType {
		var st : SchemaType = {}
		switch t {
			case Nullable(f):
				st = getSchemaType(f);
				switch f { // ignore Dynamics
					case Basic("Enum"):
					case Dyn:
					case _:
						st.type.push("null");
				}

			case Basic(name):
				switch name {
					case "String": st.type = ["string"];
					case "Int": st.type = ["integer"];
					case "Float": st.type = ["number"];
					case "Bool": st.type = ["boolean"];
					case "Enum":
				}

			case Enu(name):
				st.enum__ = allEnums.get(name);

			case Arr(t):
				st.type = ["array"];
				st.items = getSchemaType(t);

			case Obj(fields):
				st.type = ["object"];

			case Ref(display, typeName):
				st.ref__ = '#/otherTypes/${typeName.replace("ldtk.", "").replace("Json", "")}';

			case Dyn:
			case Unknown:
		}

		return st;
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
	static function getAnchorHtml(str:String) {
		return '<a id="${anchorId(str)}" name="${anchorId(str)}"></a>';
	}

	#end
}