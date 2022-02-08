package misc;

import data.DataTypes;

typedef Convertor = {
	var from: ldtk.Json.FieldType;
	var to: ldtk.Json.FieldType;
	var ?displayName: String;
	var ?mode: Null<String>;
	var lossless : Bool;
	var convertInst: (fi:data.inst.FieldInstance, arrayIdx:Int) -> Void;
	var ?convertDef: (fd:data.def.FieldDef) -> Void;
}


class FieldTypeConverter {
	static var CONVERTORS : Array<Convertor> = [
		{
			from:F_String, to:F_Text, lossless:true,
			convertInst:(fi,i)->{},
		},
		{
			from:F_Text, to:F_String, lossless:false, mode:"Remove line breaks",
			convertInst:(fi,i)->{
				if( !fi.isUsingDefault(i) ) {
					var v = fi.getString(i);
					v = StringTools.replace(v, "\n", " ");
					fi.parseValue(i, v);
				}
			},
			convertDef: (fd)->{
				if( fd.defaultOverride!=null ) {
					var v = fd.getStringDefault();
					v = StringTools.replace(v, "\n", " ");
					fd.defaultOverride = V_String(v);
				}
			}
		},
		{
			from:F_Path, to:F_String, lossless:true,
			convertInst:(fi,i)->{},
		},
		{
			from:F_String, to:F_Path, lossless:true,
			convertInst:(fi,i)->{},
		},


		{
			from:F_Int, to:F_Float, lossless:true,
			convertInst:(fi,i)->{
				fi.internalValues[i] = fi.isUsingDefault(i) ? null : V_Float( fi.getInt(i) );
			},
		},

		{
			from:F_Bool, to:F_Int, lossless:true,
			convertInst:(fi,i)->{
				fi.internalValues[i] = fi.isUsingDefault(i) ? null : V_Int( fi.getBool(i) ? 1 : 0 );
			},
			convertDef: (fd)->{
				fd.defaultOverride = V_Int( fd.getBoolDefault()==true ? 1 : 0 );
			},
		},

		{
			from:F_Float, to:F_Int, mode:"Truncate", lossless:false,
			convertInst:(fi,i)->{
				fi.internalValues[i] = fi.isUsingDefault(i) ? null : V_Int( Std.int( fi.getFloat(i) ) );
			},
			convertDef: (fd)->{
				if( fd.min!=null ) fd.min = Std.int( fd.min );
				if( fd.max!=null ) fd.max = Std.int( fd.max );
				fd.setDefault( Std.string( Std.int( fd.getFloatDefault() ) ) );
			}
		},

		{
			from:F_Float, to:F_Int, mode:"Round", lossless:false,
			convertInst:(fi,i)->{
				fi.internalValues[i] = fi.isUsingDefault(i) ? null : V_Int( M.round( fi.getFloat(i) ) );
			},
			convertDef: (fd)->{
				if( fd.min!=null ) fd.min = M.round( fd.min );
				if( fd.max!=null ) fd.max = M.round( fd.max );
				fd.setDefault( Std.string( M.round( fd.getFloatDefault() ) ) );
			}
		},
	];


	static var TO_ARRAY_CONVERTOR : Convertor = {
		displayName: "Turn into array",
		from:null, to:null, lossless:true,
		convertInst:(fi,i)->{},
		convertDef: (fd)->{
			fd.isArray = true;
		}
	}



	public static inline function getAllConvertors(fd:data.def.FieldDef) {
		var all = CONVERTORS.filter( (c)->c.from==null || c.from.equals(fd.type) );
		if( !fd.isArray )
			all.insert(0,TO_ARRAY_CONVERTOR);
		return all;
	}

	public static function convert(p:data.Project, fd:data.def.FieldDef, c:Convertor, onSuccess:Void->Void) {
		if( c==null )
			throw "Unsupported conversion";

		var oldProject = p.clone();
		var ops = [];

		var toType = c.to!=null ? c.to : fd.type;

		// Convert field instances
		for(w in Editor.ME.project.worlds)
		for(l in w.levels)
		for(li in l.layerInstances)
			if( li.def.type==Entities )
				for( ei in li.entityInstances )
				for(fi in ei.fieldInstances)
					if( fi.defUid==fd.uid ) {
						for(i in 0...fi.getArrayLength())
							ops.push({
								label: 'Converting ${l.identifier}.${ei.def.identifier}.${fd.identifier} to $toType',
								cb: c.convertInst.bind(fi,i),
							});
					}

		// Updating fieldDef
		ops.push({
			label: "Updating field definition",
			cb: ()-> {
				if( c.convertDef!=null )
					c.convertDef(fd);
				if( c.to!=null )
					fd.type = c.to;
			},
		});

		new ui.modal.Progress("Type conversion", ops, ()->{
			N.success("Type changed to "+toType);
			new ui.LastChance(L.t._("Type conversion"), oldProject);
			onSuccess();
		});
	}
}