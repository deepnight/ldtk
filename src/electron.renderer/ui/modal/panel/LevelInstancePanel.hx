package ui.modal.panel;

class LevelInstancePanel extends ui.modal.Panel {
	var levelForm : LevelInstanceForm;

	public function new() {
		super();

		loadTemplate("levelInstancePanel");
		linkToButton("button.editLevelInstance");

		// Level instance form
		levelForm = new ui.LevelInstanceForm(jContent.find("#levelInstanceForm"), true);

		checkBackup();
	}

	override function onDispose() {
		super.onDispose();
		levelForm.dispose();
	}

	override function onGlobalEvent(ge:GlobalEvent) {
		super.onGlobalEvent(ge);

		// Might happen when an event is fired during the constructor call
		if( levelForm==null )
			return;

		switch ge {
			case WorldMode(true):
				close();

			case LevelSelected(l):
				if( !levelForm.isUsingLevel(l) )
					close();

			case LevelRemoved(l):
				if( levelForm.isUsingLevel(l) )
					close();

			case _:
		}

		// Forward events
		if( !isClosing() )
			levelForm.onGlobalEvent(ge);
	}
}