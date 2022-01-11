package ui.vp;

class EntityRefPicker extends ui.ValuePicker<data.inst.EntityInstance> {
	var sourceEi : data.inst.EntityInstance;
	var fd : data.def.FieldDef;

	public function new(sourceEi:data.inst.EntityInstance, fd:data.def.FieldDef) {
		super();
		this.sourceEi = sourceEi;
		this.fd = fd;

		var targetName = switch fd.allowedRefs {
			case Any: "any entity";
			case OnlySame: "another "+sourceEi.def.identifier;
		}
		var location = fd.allowOutOfLevelRef ? "in any level" : "in this level";
		setInstructions("Pick "+targetName+" "+location);
	}

	override function cancel() {
		super.cancel();
		var cr = project.getCachedRef(sourceEi.iid);
		if( cr!=null && cr.level!=curLevel ) {
			editor.selectLevel(cr.level);
			editor.camera.scrollTo(sourceEi.worldX, sourceEi.worldY);
		}
	}

	override function onEnter(ei:data.inst.EntityInstance) {
		super.onEnter(ei);
	}

	override function onLeave(ei:data.inst.EntityInstance) {
		super.onLeave(ei);
	}

	override function pickAt(m:Coords) {
		var m = m.clone();
		for(li in curLevel.layerInstances) {
			if( !li.visible || li.def.type!=Entities )
				continue;

			m.setRelativeLayer(li);
			for(ei in li.entityInstances)
				if( isValidPick(ei) && ei.isOver(m.layerX,m.layerY) )
					return ei;
		}
		return null;
	}


	override function isValidPick(ei:data.inst.EntityInstance):Bool {
		// Not same level
		if( !fd.allowOutOfLevelRef && ei._li.level!=sourceEi._li.level  )
			return false;

		// Not right entity type
		return ei!=sourceEi && switch fd.allowedRefs {
			case Any: true;
			case OnlySame: ei.def.identifier==sourceEi.def.identifier;
		}
	}

	override function update() {
		super.update();

		if( !fd.allowOutOfLevelRef && ( curLevel!=sourceEi._li.level || editor.worldMode ) )
			setError("You can only pick a reference in the same level for this value.");
		else
			setError();
	}
}