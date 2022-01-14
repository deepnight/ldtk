package ui.vp;

class EntityRefPicker extends ui.ValuePicker<data.inst.EntityInstance> {
	var sourceEi : data.inst.EntityInstance;
	var fd : data.def.FieldDef;
	var validTargetsInvalidated = true;

	public function new(sourceEi:data.inst.EntityInstance, fd:data.def.FieldDef) {
		super();
		this.sourceEi = sourceEi;
		this.fd = fd;

		var targetName = switch fd.allowedRefs {
			case Any: "any entity";
			case OnlyTags: "any entity with tag "+"TODO";
			case OnlySame: "another "+sourceEi.def.identifier;
		}
		var location = fd.allowOutOfLevelRef ? "in any level" : "in this level";
		setInstructions("Pick "+targetName+" "+location);
	}

	override function onGlobalEvent(ev:GlobalEvent) {
		super.onGlobalEvent(ev);

		switch ev {
			case WorldMode(active):
				if( !active )
					validTargetsInvalidated = true;

				if( !fd.allowOutOfLevelRef && ( curLevel!=sourceEi._li.level || active ) )
					setError("You can only pick a reference in the same level for this value.");
				else
					setError();


			case LevelSelected(level):
				validTargetsInvalidated = true;

			case _:
		}
	}

	function renderValidTargets() {
		editor.levelRender.clearTemp();

		var n = 0;
		var g = editor.levelRender.temp;
		for(li in curLevel.layerInstances)
		for( ei in li.entityInstances )
			if( isValidPick(ei) ) {
				g.lineStyle(1, 0xffcc00);
				g.drawCircle(ei.centerX, ei.centerY, M.imax(ei.width, ei.height)*0.5 + 8);
				g.lineStyle(1, 0xffcc00, 0.33);
				g.drawCircle(ei.centerX, ei.centerY, M.imax(ei.width, ei.height)*0.5 + 12);
				n++;
			}

		if( n==0 )
			setError("No valid target in this level.");
	}

	override function cancel() {
		super.cancel();
		goBackToSource();
	}

	function goBackToSource() {
		if( sourceEi._li.level!=curLevel ) {
			editor.selectLevel(sourceEi._li.level);
			editor.camera.scrollTo(sourceEi.worldX, sourceEi.worldY);
		}

		if( sourceEi._li!=curLayerInstance )
			editor.selectLayerInstance(sourceEi._li);
	}

	override function onEnter(ei:data.inst.EntityInstance) {
		super.onEnter(ei);
	}

	override function onLeave(ei:data.inst.EntityInstance) {
		super.onLeave(ei);
	}

	override function onPick(v:data.inst.EntityInstance) {
		super.onPick(v);
		goBackToSource();
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

		// No double-references
		if( sourceEi.hasEntityRefTo(ei, fd) )
			return false;

		// Not right entity type
		return ei!=sourceEi && switch fd.allowedRefs {
			case Any: true;
			case OnlyTags: ei.def.tags.hasAnyTagFoundIn(fd.allowedRefTags);
			case OnlySame: ei.def.identifier==sourceEi.def.identifier;
		}
	}

	override function postUpdate() {
		super.postUpdate();

		if( validTargetsInvalidated ) {
			validTargetsInvalidated = false;
			renderValidTargets();
		}
	}

	override function update() {
		super.update();

		editor.levelRender.temp.alpha = M.fabs( Math.cos(ftime*0.07) );
	}
}