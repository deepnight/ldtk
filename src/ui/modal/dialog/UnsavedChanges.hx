package ui.modal.dialog;

class UnsavedChanges extends ui.modal.Dialog {
	public function new(?target:js.jquery.JQuery, onSave:Void->Void, onClose:Void->Void) {
		super(target, "unsavedChanges");

		jContent.text( L.t._("Do you want to save before leaving?") );

		addButton(L.t._("Yes"), "save", function() {
			onSave();
			onClose();
		});

		addButton(L.t._("No"), onClose);

		addCancel();
	}
}