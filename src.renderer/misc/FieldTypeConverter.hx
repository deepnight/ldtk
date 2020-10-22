package misc;

import data.LedTypes;

typedef Convertor = {
	var from: FieldType;
	var to: FieldType;
	var ?mode: Null<String>;
	var lossless : Bool;
	var convertInst: (fi:data.inst.FieldInstance, arrayIdx:Int) -> Void;
	var ?convertDef: (fd:data.def.FieldDef) -> Void;
}


class FieldTypeConverter {
	static var CONVERTORS : Array<Convertor> = [
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



	static function getConvertor(from:FieldType, to:FieldType, ?mode:String) {
		for(c in CONVERTORS)
			if( c.from.equals(from) && c.to.equals(to) && mode==c.mode )
				return c;
		return null;
	}

	public static inline function getAllConvertors(type:FieldType) {
		return CONVERTORS.filter( (c)->c.from.equals(type) );
	}

	public static inline function canConvert(from:FieldType, to:FieldType) {
		return getConvertor(from,to) != null;
	}

	public static inline function isLossless(from:FieldType, to:FieldType) {
		var c = getConvertor(from,to);
		return c!=null && c.lossless;
	}



	public static function convert(p:data.Project, ed:data.def.EntityDef, fd:data.def.FieldDef, c:Convertor) {
		if( c==null )
			throw "Unsupported conversion";

		var oldProject = data.Project.fromJson( p.toJson() );
		var ops = [];

		// Convert field instances
		for(l in Editor.ME.project.levels)
		for(li in l.layerInstances)
			if( li.def.type==Entities )
				for( ei in li.entityInstances )
				for(fi in ei.fieldInstances)
					if( fi.defUid==fd.uid ) {
						for(i in 0...fi.getArrayLength())
							ops.push({
								label: 'Converting ${l.identifier}.${ei.def.identifier}.${fd.identifier} to ${c.to}',
								cb: c.convertInst.bind(fi,i),
							});
					}

		// Updating fieldDef
		ops.push({
			label: "Updating field definition",
			cb: ()-> {
				if( c.convertDef!=null )
					c.convertDef(fd);
				fd.type = c.to;
			},
		});

		new ui.modal.Progress("Type conversion", ops, ()->{
			N.success("Type changed to "+c.to);
			Editor.ME.ge.emit( EntityFieldDefChanged(ed) );
			new ui.LastChance(L.t._("Type conversion"), oldProject);
		});
	}
}