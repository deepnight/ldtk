package ui.vp;

class LevelSpotPicker extends ui.ValuePicker<Coords> {
	var initialWorldMode = false;

	public function new() {
		super();

		setInstructions("Pick a spot for a new level");

		initialWorldMode = editor.worldMode;
		if( !editor.worldMode )
			editor.setWorldMode(true);
	}

	override function onGlobalEvent(ev:GlobalEvent) {
		super.onGlobalEvent(ev);

		switch ev {
			case WorldMode(active):
				if( !active )
					cancel();

			case _:
		}
	}

	override function shouldCancelLeftClickEventAt(m:Coords):Bool {
		return true;
	}

	override function onMouseMoveCursor(ev:hxd.Event, m:Coords) {
		super.onMouseMoveCursor(ev, m);
		ev.cancel = true;
		editor.cursor.set(Add);
	}

	override function onMouseMove(ev:hxd.Event, m:Coords) {
		super.onMouseMove(ev, m);
		ev.cancel = true;
	}

	function goBackToSource() {
		if( editor.worldMode!=initialWorldMode )
			editor.setWorldMode( initialWorldMode );
	}

	override function pickAt(m:Coords) {
		// var m = m.clone();
		// for(li in curLevel.layerInstances) {
		// 	if( !li.visible || li.def.type!=Entities )
		// 		continue;

		// 	m.setRelativeLayer(li);
		// 	for(ei in li.entityInstances)
		// 		if( isValidPick(ei) && ei.isOver(m.layerX,m.layerY) )
		// 			return ei;
		// }
		return null;
	}


	override function isValidPick(c:Coords):Bool {
		return false;
		// Not same level
		// if( !fd.allowOutOfLevelRef && ei._li.level!=sourceEi._li.level  )
		// 	return false;

		// // No double-references
		// if( sourceEi.hasEntityRefTo(ei, fd) )
		// 	return false;

		// // Not right entity type
		// return ei!=sourceEi && switch fd.allowedRefs {
		// 	case Any: true;
		// 	case OnlyTags: ei.def.tags.hasAnyTagFoundIn(fd.allowedRefTags);
		// 	case OnlySame: ei.def.identifier==sourceEi.def.identifier;
		// }
	}
}