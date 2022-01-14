package ui.modal.panel;

class EditLevelFieldDefs extends ui.modal.Panel {
	var fieldForm : FieldDefsForm;

	public function new() {
		super();

		loadTemplate("editLevelFieldDefs");

		fieldForm = new FieldDefsForm(FP_Level);
		jContent.find("#levelFields").replaceWith(fieldForm.jWrapper);
		fieldForm.useFields( "Level", project.defs.levelFields );
	}

	override function onClose() {
		super.onClose();
		if( !Modal.hasAnyOpen() )
			new LevelInstancePanel();
	}


	override function onGlobalEvent(ge:GlobalEvent) {
		super.onGlobalEvent(ge);

		switch ge {
			case ProjectSelected:
				fieldForm.useFields( "Level", project.defs.levelFields );

			case _:
		}
	}
}