package misc;

import data.LedTypes;

typedef Convertor = {
	var from: FieldType;
	var to: FieldType;
	var lossless : Bool;
	var convert: (fi:data.inst.FieldInstance, idx:Int) -> Void;
}

class FieldTypeConverter {
	static var CONVERTORS : Array<Convertor> = [
		{ from:F_String, to:F_Text, lossless:true, convert:(fi,i)->{} },
		{ from:F_Text, to:F_String, lossless:false, convert:(fi,i)->{} },

		{ from:F_Int, to:F_Float, lossless:true, convert:(fi,i)->{
			fi.internalValues[i] = V_Float(fi.getInt(i));
		} },
		{ from:F_Float, to:F_Int, lossless:false, convert:(fi,i)->{
			fi.internalValues[i] = V_Int( Std.int(fi.getFloat(i)) );
		} },
	];

	static function getConvertor(from:FieldType, to:FieldType) {
		for(c in CONVERTORS)
			if( c.from.equals(from) && c.to.equals(to) )
				return c;
		return null;
	}

	public static inline function canConvert(from:FieldType, to:FieldType) {
		return getConvertor(from,to) != null;
	}

	public static inline function isLossless(from:FieldType, to:FieldType) {
		var c = getConvertor(from,to);
		return c!=null && c.lossless;
	}



	public static function convert(p:data.Project, ed:data.def.EntityDef, fd:data.def.FieldDef, newType:FieldType) {
		var ops = [];
		var c = getConvertor(fd.type, newType);
		if( c==null )
			throw "Unsupported conversion";

		var oldProject = data.Project.fromJson( p.toJson() );

		// Convert field instances
		for(l in Editor.ME.project.levels)
		for(li in l.layerInstances)
			if( li.def.type==Entities )
				for( ei in li.entityInstances )
				for(fi in ei.fieldInstances)
					if( fi.defUid==fd.uid ) {
						for(i in 0...fi.getArrayLength())
							ops.push({
								label: 'Converting ${l.identifier}.${ei.def.identifier}.${fd.identifier} to $newType',
								cb: c.convert.bind(fi,i),
							});
					}

		// Change def type
		ops.push({
			label: "Changing definition type",
			cb: ()-> fd.type = newType,
		});

		new ui.modal.Progress("Type conversion", ops, ()->{
			N.success("Type changed to "+newType);
			Editor.ME.ge.emit( EntityFieldDefChanged(ed) );
			new ui.LastChance(L.t._("Type conversion"), oldProject);
		});
	}
}