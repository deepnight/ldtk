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
	Multiple(possibleTypes:Array<FieldType>);
	Unknown;
}

typedef DeprecationInfos = {
	var start : dn.Version;
	var removal : dn.Version;
	var replacement : Null<String>;
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
	var deprecation: Null<DeprecationInfos>;
	var removed: Null<dn.Version>;
}

typedef GlobalType = {
	var rawName : String;
	var displayName : String;
	var xml : haxe.xml.Access;
	var section : String;
	var description : Null<String>;
	var onlyInternalFields : Bool;
	var inlined: Bool;
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
	var ?oneOf: Array<SchemaType>;
	var ?anyOf: Array<SchemaType>;
}


class DocGenerator {
	#if( macro || display )
	static var allGlobalTypes: Array<GlobalType>;
	static var allEnums : Map<String, Array<String>>;
	static var verbose = false;
	static var appVersion = new dn.Version();

	/**
		Generate Markdown doc and Json schema
	**/
	public static function run(className:String, xmlPath:String, ?mdPath:String, ?jsonPath:String, ?minimalJsonPath:String, deleteXml=false) {
		allGlobalTypes = [];
		allEnums = [];

		// Read app version from "package.json"
		haxe.macro.Context.registerModuleDependency("DocGenerator", "app/package.json");
		var raw = sys.io.File.getContent("app/package.json");
		var versionReg = ~/"version"[ \t]*:[ \t]*"(.*)"/gim;
		versionReg.match(raw);
		appVersion.set( versionReg.matched(1) );
		Sys.println('App version is $appVersion...');

		// Read XML file
		if( verbose )
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
						case _:
							if( n.has.a )
								enumValues.push(n.name+"(...)");
							else
								enumValues.push(n.name);
					}

				allEnums.set(type.att.path, enumValues);
			}
			else {
				// Typedef
				allGlobalTypes.push({
					xml: type,
					description: type.hasNode.haxe_doc ? type.node.haxe_doc.innerHTML : null,
					rawName: type.att.path,
					displayName: displayName,
					section: hasMeta(type,"section") ? getMeta(type,"section") : "",
					onlyInternalFields: hasMeta(type,"internal"),
					inlined: hasMeta(type,"inline"),
				});
			}

			if( verbose )
				Sys.println('Found ${type.name}: $displayName');
		}
		if( verbose )
			Sys.println("");

		// Sort types
		allGlobalTypes.sort( (a,b)->{
			if( a.section!=null && b.section==null ) return 1;
			if( a.section==null && b.section!=null ) return -1;
			if( a.section==null && b.section==null )
				return Reflect.compare(a.displayName, b.displayName);
			else
				return Reflect.compare(a.section, b.section);
		});

		// Markdown doc output
		Sys.println("Generating Markdown doc...");
		genMarkdownDoc(xml, className, xmlPath, mdPath);
		if( verbose )
			Sys.println("");

		// Json schema output
		Sys.println("Generating JSON schema...");
		genJsonSchema(xml, className, xmlPath, jsonPath, false);

		// Minimal Json schema output
		Sys.println("Generating Minimal JSON schema...");
		genJsonSchema(xml, className, xmlPath, minimalJsonPath, true);

		// Dump version to version.txt
		Sys.println("Dumping version file...");
		sys.io.File.saveContent("docs/version.txt", appVersion.full);

		// Cleanup
		if( deleteXml ) {
			Sys.println("Deleting XML file");
			sys.FileSystem.deleteFile(xmlPath);
		}

		Sys.println("");
		Sys.println('Done!');
		Sys.println('');
	}


	static function getGlobalType(typePath:String) : GlobalType {
		for( t in allGlobalTypes )
			if( t.rawName==typePath )
				return t;

		throw 'Unknown global type $typePath';
	}


	/**
		Build doc
	**/
	static function genMarkdownDoc(xml:haxe.xml.Access, className:String, xmlPath:String, ?mdPath:String) {
		// Print types
		var root : GlobalType = null;
		var md = [];
		for(type in allGlobalTypes) {
			if( type.inlined )
				continue;

			if( type.section=="1" )
				root = type;

			md.push("");
			var depth = 0;

			if( verbose )
				Sys.println('${type.displayName}:');


			// Anchor
			md.push( getAnchorHtml(type.xml.att.path) );

			// Type title
			var title = '${type.displayName} ${versionBadge(type.xml)}';
			if( type.section!="" )
				title = type.section+". "+title;
			md.push('## $title');

			// Optional description
			if( type.description!=null ) {
				md.push(type.description);
				md.push("");
			}

			// No field informations for this type
			if( !type.xml.hasNode.a ) {
				// md.push('Sorry this type has no documentation yet.');
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
				var cell = [];
				if( f.removed==null )
					cell.push('`${f.displayName}`');
				else
					cell.push('~~${f.displayName}~~');


				if( f.only!=null )
					cell.push('<sup class="only">Only *${f.only}*</sup>');

				if( f.isInternal || type.onlyInternalFields )
					cell.push('<sup class="internal">*Only used by editor*</sup>');

				if( f.deprecation!=null ) {
					cell[0] = "~~"+cell[0]+"~~";
					cell.push('<sup class="deprecated">*DEPRECATED!*</sup>');
				}

				if( f.hasVersion )
					cell.push( versionBadge(f.xml) );

				tableCols.push( cell.join("<br/>") );

				// Type
				var type = '${getTypeMd(f.type)}';
				type = StringTools.replace(type," ","&nbsp;");
				if( f.isColor )
					type+="<br/>"+getColorInfosMd(f);
				tableCols.push(type);

				// Desc
				if( f.removed!=null ) {
					tableCols.push('*This field was removed in ${f.removed.full} and should no longer be used.*');
				}
				else {
					var cell = f.descMd;

					if( f.subFields.length>0 ) {
						if( isArray(f.type) )
							cell.push("This array contains objects with the following fields:");
						else
							cell.push("This object contains the following fields:");
						cell.push( getSubFieldsHtml( f.subFields ) );
					}
					tableCols.push( cell.join("<br/> ") );
				}

				md.push( tableCols.join(" | "));
				for(row in subRows)
					md.push("| "+row+" |");
			}
		}


		// Header
		var headerMd = [
			'# LDtk Json structure (version $appVersion)',
			'',
		];
		md = headerMd.concat(md);


		// Write markdown file
		if( mdPath==null ) {
			var fp = dn.FilePath.fromFile(xmlPath);
			fp.extension = "md";
			mdPath = fp.full;
		}

		if( verbose )
			Sys.println(' > Writing: ${mdPath}...');
		var fo = sys.io.File.write(mdPath, false);
		fo.writeString(md.join("\n"));
		fo.close();
	}



	/**
		Build Json schema
	**/
	static function genJsonSchema(xml:haxe.xml.Access, className:String, xmlPath:String, ?jsonPath:String, isMinimal:Bool) {
		// Prepare Json structure
		var json = {
			LdtkJsonRoot: null,
			otherTypes: new Map<String,Dynamic>(),
		};

		var otherTypes = [];

		for(type in allGlobalTypes) {

			// No field informations for this type?
			if( !type.xml.hasNode.a )
				continue;

			// Init json type
			var typeName = type.rawName.substr( type.rawName.lastIndexOf(".")+1 ).replace("Json","");
			var typeJson : SchemaType = {}
			typeJson.type = ["object"];
			if( type.description!=null )
				typeJson.description = type.description.replace("\n"," ");
			typeJson.properties = [];
			typeJson.required = [];
			typeJson.title = type.displayName;


			// List fields
			for(f in getFieldsInfos(type.xml.node.a)) {
				if( (f.removed != null || f.isInternal || type.onlyInternalFields || f.deprecation != null) && isMinimal )
					continue;

				var subType = getSchemaType(f.type);
				subType.description = f.descMd.join('\n');

				if( f.removed!=null )
					subType.description = '*This field was removed in ${f.removed.full} and should no longer be used.*';

				// Detect non-nullable fields
				if( f.deprecation==null ) {
					var req = switch f.type {
						case Nullable(_): false;
						case _: true;
					}
					if( req )
						typeJson.required.push(f.displayName);
				}

				typeJson.properties.set(f.displayName, subType);
			}

			// Store type
			if( typeName=="Project" )
				json.LdtkJsonRoot = typeJson;
			else {
				typeJson.additionalProperties = false;
				json.otherTypes.set(typeName, typeJson);
				otherTypes.push(typeName);
			}
		}

		// Force refs to all otherTypes (otherwise they are lost by Quicktype conversion)
		if( otherTypes.length>0 ) {
			json.LdtkJsonRoot.properties.set("__FORCED_REFS", {
				description: "This object is not actually used by LDtk. It ONLY exists to force explicit references to all types, to make sure QuickType finds them and integrate all of them. Otherwise, Quicktype will drop types that are not explicitely used.",
				type: ["object"],
				properties: new Map(),
			});
			var forcedMap = json.LdtkJsonRoot.properties.get("__FORCED_REFS").properties;
			for(t in otherTypes)
				forcedMap.set( t, { ref__: makeSchemaRef(t) } );
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
			title: "LDtk "+appVersion.full+" JSON schema",
			version: appVersion.full,
			description: "This file is a JSON schema of files created by LDtk level editor (https://ldtk.io).",
			"$ref" : "#/LdtkJsonRoot",
		}
		if( verbose )
			Sys.println(' > Writing: ${jsonPath}...');
		var fo = sys.io.File.write(jsonPath, false);
		var jsonStr = dn.data.JsonPretty.stringify(json, Full, header, true);
		jsonStr = jsonStr.replace('"ref__"', "\"$ref\"");
		jsonStr = jsonStr.replace('"enum__"', '"enum"');
		fo.writeString(jsonStr);
		fo.close();
	}


	static function getColorInfosMd(f:FieldInfos) : String {
		return '<small class="color"> *' + ( switch f.type {
			case Nullable(Basic("String")), Basic("String"):
				'Hex color "#rrggbb"';

			case Nullable(Basic("UInt")), Basic("UInt"), Nullable(Basic("Int")), Basic("Int"):
				'Hex color 0xrrggbb';

			case _:
				'???';
		} ) + '* </small>';
	}


	static function getSubFieldsHtml(fields:Array<FieldInfos>) {
		var list = [];
		for(f in fields) {
			var li = [];
			// Name
			if( f.removed==null )
				li.push('**`${f.displayName}`**');
			else
				li.push('~~${f.displayName}~~');

			// Type
			li.push('**(${getTypeMd(f.type, f.removed!=null)}**)');

			// Version badges
			if( f.hasVersion )
				li.push( versionBadge(f.xml) );

			// Color
			if( f.isColor )
				li.push( getColorInfosMd(f) );

			// Desc
			if( f.removed!=null )
				li.push('*This field was removed in ${f.removed.full} and should no longer be used.*');
			else if( f.descMd.length>0 ) {
				li.push(":");
				for( descLine in f.descMd )
					li.push('*$descLine*');
			}

			// Sub fields
			if( f.subFields.length>0 )
				li.push( getSubFieldsHtml(f.subFields) );

			list.push( li.join(" ") );
		}

		return "<ul class='subFields'><li>" + list.join("</li><li>") + "</li></ul>";
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

			var deprecation : Null<DeprecationInfos> =
				!hasMeta(fieldXml,"deprecation")
					? null
					: {
						start: new dn.Version( getMeta(fieldXml,"deprecation",0) ),
						removal: new dn.Version( getMeta(fieldXml,"deprecation",1) ),
						replacement: getMeta(fieldXml,"deprecation",2),
					}

			var descMd = [];
			if( deprecation!=null ) {
				if( appVersion.compareEverything(deprecation.removal)<0 ) {
					/*
						WARNING!! Changing this text might break the JsonDoc template on the website!
						Make sure to update the template if needed.
					*/
					descMd.push('**WARNING**: this deprecated value will be *removed* completely on version ${deprecation.removal}+');

				}
				else
					descMd.push('**WARNING**: this deprecated value is no longer exported since version ${deprecation.removal}');

				descMd.push('');
				if( deprecation.replacement!=null )
					descMd.push('Replaced by: `${deprecation.replacement}`');
			}

			var type = getFieldType(fieldXml);
			var subFields = [];
			if( deprecation==null ) {
				if( fieldXml.hasNode.haxe_doc ) {
					var html = fieldXml.node.haxe_doc.innerHTML;
					html = StringTools.replace(html, "<![CDATA[", "");
					html = StringTools.replace(html, "]]>", "");
					html = StringTools.replace(html, "\n", "<br/>");
					descMd.push(html);
				}

				subFields = switch type {
					case Obj(f), Nullable( Obj(f) ): f;
					case Arr(Obj(f)), Nullable( Arr(Obj(f)) ): f;
					case Ref(_,t), Nullable( Ref(_,t) ),
						Arr(Ref(_,t)), Nullable( Arr(Ref(_,t)) ):
						var gt = getGlobalType(t);
						if( gt.inlined )
							getFieldsInfos(gt.xml.node.a);
						else
							[];

					case _: [];
				}

				switch type {
					case Enu(name), Arr(Enu(name)):
						descMd.push("Possible values: `"+allEnums.get(name).join("`, `")+"`");

					case Nullable(Enu(name)):
						descMd.push("Possible values: &lt;`null`&gt;, `"+allEnums.get(name).join("`, `")+"`");

					case _:
				}
			}

			// Replace @enum{...} with Enum possible values
			var typeRefReg = ~/@enum{(.*?)}/im;
			for(i in 0...descMd.length) {
				if( typeRefReg.match(descMd[i]) ) {
					var tmp = descMd[i];
					while( typeRefReg.match(tmp) ) {
						var k = typeRefReg.matched(1);
						descMd[i] = StringTools.replace( descMd[i], "@enum{"+k+"}", allEnums.get(k).join(", ") );
						tmp = typeRefReg.matchedRight();
					}
				}
			}

			allFields.push({
				xml: fieldXml,
				displayName: displayName,
				type: type,
				subFields: subFields,

				only: getMeta(fieldXml, "only"),
				hasVersion: hasMeta(fieldXml,"changed") || hasMeta(fieldXml,"added") || hasMeta(fieldXml,"removed") || hasMeta(fieldXml,"deprecation"),
				descMd: descMd,
				isColor: hasMeta(fieldXml, "color"),
				isInternal: hasMeta(fieldXml, "internal"),
				deprecation: deprecation,
				removed: hasMeta(fieldXml,"removed") ? getMetaVersion(fieldXml,"removed") : null,
			});
		}
		allFields.sort( (a,b)->{
			if( a.deprecation!=b.deprecation )
				if( a.deprecation!=null )
					return 1;
				else
					return -1;
			if( a.isInternal!=b.isInternal )
				if( a.isInternal )
					return 1;
				else
					return -1;
			else
				return Reflect.compare(a.displayName, b.displayName);
		});

		return allFields;
	}


	/**
		Create a version info badge ("added/changed/removed" meta)
	**/
	static function versionBadge(xml:haxe.xml.Access) {
		var badges = [];

		if( hasMeta(xml,"added") ) {
			var version = getMeta(xml,"added");
			badges.push( badge("Added", version, appVersion.hasSameMajorAndMinor(version) ? "green" : "gray" ) );
		}

		if( hasMeta(xml,"changed") ) {
			var version = getMeta(xml,"changed");
			badges.push( badge("Changed", version, appVersion.hasSameMajorAndMinor(version) ? "green" : "gray" ) );
		}

		if( hasMeta(xml,"deprecation") ) {
			var endVer = getMeta(xml,"deprecation", 1);
			if( dn.Version.lowerEq(endVer, appVersion.numbers, true) )
				badges.push( badge("Removed", endVer, appVersion.hasSameMajorAndMinor(endVer) ? "green" : "gray" ) );
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
	static function hasMeta(xml:haxe.xml.Access, name:String, metaIndex=0) {
		if( !xml.hasNode.meta || !xml.node.meta.hasNode.m )
			return false;

		for(m in xml.node.meta.nodes.m )
			if( m.att.n==name ) {
				if( metaIndex==0 && !m.hasNode.e )
					return true;
				var i = 0;
				for(metaValue in m.nodes.e) {
					if( i++>=metaIndex )
						return true;
				}
			}

		return false;
	}


	/**
		Get meta data of a field as String
	**/
	static function getMeta(xml:haxe.xml.Access, name:String, metaIndex=0) : Null<String> {
		if( !hasMeta(xml,name) )
			return null;

		for(m in xml.node.meta.nodes.m )
			if( m.att.n == name ) {
				var i = 0;
				for(metaValues in m.nodes.e) {
					if( i++<metaIndex )
						continue;
					var v = metaValues.innerHTML;
					if( v.charAt(0)=="\"" )
						return v.substring(1, v.length-1);
					else
						return v;
				}
			}

		throw "Malformed meta?";
	}


	/**
		Get meta data of a field as String
	**/
	static function getMetaArray(xml:haxe.xml.Access, name:String, metaIndex=0) : Array<String> {
		if( !hasMeta(xml,name) )
			return [];

		var out = [];
		for(m in xml.node.meta.nodes.m )
			if( m.att.n == name ) {
				var i = 0;
				for(metaValues in m.nodes.e) {
					if( i++<metaIndex )
						continue;
					var v = metaValues.innerHTML;
					if( v.charAt(0)=="\"" )
						out.push( v.substring(1, v.length-1) );
					else
						out.push(v);
				}
			}

		if( out.length>0 )
			return out;
		else
			throw "Malformed meta?";
	}


	/**
		Get meta data of a field as dn.Version
	**/
	static function getMetaVersion(xml:haxe.xml.Access, name:String) : Null<dn.Version> {
		return new dn.Version( getMeta(xml, name) );
	}


	static function metaTypeToFieldType(rawType:String) : FieldType {
		return switch rawType {
			case "Int", "Float", "Bool", "String":
				// Basic types
				Basic(rawType);

			case "Dynamic":
				Dyn;

			case _:
				// Reference to a global type
				var global = getGlobalType(rawType);
				Ref(global.displayName, global.rawName);
		}
	}


	/**
		Return the type Enum of a specific field XML
	**/
	static function getFieldType(fieldXml:haxe.xml.Access) : FieldType {
		return
			if( hasMeta(fieldXml, "docType") ) {
				// Custom specific type for schema export
				metaTypeToFieldType( getMeta(fieldXml, "docType") );
			}
			else if( fieldXml.hasNode.x ) {
				if( fieldXml.node.x.att.path=="Null" )
					Nullable( getFieldType(fieldXml.node.x) );
				else
					Basic(fieldXml.node.x.att.path);
			}
			else if( fieldXml.hasNode.d ) {
				// Dynamic
				var rawPossibleTypes = getMetaArray(fieldXml,"types");
				if( rawPossibleTypes.length>0 ) {
					// Known possible types
					var types = [];
					for(t in rawPossibleTypes) {
						var ft = metaTypeToFieldType(t);
						if( ft!=null )
							types.push(ft);
					}
					Multiple(types);
				}
				else {
					// Pure dynamic
					Dyn;
				}
			}
			else if( fieldXml.hasNode.t ) {
				var name = fieldXml.node.t.att.path;
				var typeInfos = allGlobalTypes.filter( (t)->t.rawName==name )[0];
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


	static function isArray(t:FieldType) {
		return switch t {
			case Nullable(f): isArray(f);
			case Arr(t): true;
			case _: false;
		}
	}

	/**
		Human readable type
	**/
	static function getTypeMd(t:FieldType, ignoreNullable=false) {
		var str = switch t {
			case Nullable(f):
				ignoreNullable ? getTypeMd(f) : getTypeMd(f)+" *(can be `null`)*";

			case Basic(name):
				switch name {
					case "UInt": "Unsigned integer";
					case _: name;
				}
			case Enu(name): 'Enum';
			case Ref(display, name):
				var gt = getGlobalType(name);
				if( gt.inlined )
					'Object';
				else
					'[$display](#${anchorId(name)})';

			case Arr(t): 'Array of ${getTypeMd(t)}';
			case Obj(fields): "Object";

			case Multiple(possibleTypes):
				// "Any of: "+possibleTypes.map( t->getTypeMd(t) ).join(", ");
				"Various possible types";

			case Dyn:
				"Untyped";

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

					case Multiple(possibleTypes):
						// st.oneOf = [ { type: ["null"] } ];
						// for(ft in possibleTypes)
						// 	st.oneOf.push( getSchemaType(ft) );

					case Ref(_):
						st.oneOf = [
							{ type: ["null"] },
							{ ref__: st.ref__ },
						];
						Reflect.deleteField(st, "ref__");

					case _:
						if( st.enum__!=null )
							st.enum__.push(null);
						else
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
				st.ref__ = makeSchemaRef(typeName);

			case Dyn:

			case Multiple(possibleTypes):
				// st.oneOf = [];
				// for(ft in possibleTypes)
				// 	st.oneOf.push( getSchemaType(ft) );

			case Unknown:
		}

		return st;
	}

	static function makeSchemaRef(typeName:String) {
		return '#/otherTypes/${typeName.replace("ldtk.", "").replace("Json", "")}';
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