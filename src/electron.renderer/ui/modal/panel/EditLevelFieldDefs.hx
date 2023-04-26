package ui.modal.panel;

class EditLevelFieldDefs extends ui.modal.Panel {
	var fieldForm : FieldDefsForm;

	public function new() {
		super();

		loadTemplate("editLevelFieldDefs");

		fieldForm = new FieldDefsForm( FP_Level(null) );
		jContent.find("#levelFields").replaceWith(fieldForm.jWrapper);
		fieldForm.useFields( FP_Level(editor.curLevel), project.defs.levelFields );
	}

	override function onClose() {
		super.onClose();
		if( !Modal.hasAnyOpen() )
			new LevelInstancePanel();
	}

	public function selectField(fd:data.def.FieldDef) {
		fieldForm.selectField(fd);
	}

	override function onGlobalEvent(ge:GlobalEvent) {
		super.onGlobalEvent(ge);

		switch ge {
			case ProjectSelected:
				fieldForm.useFields( FP_Level(editor.curLevel), project.defs.levelFields );

			case _:
		}
	}
}