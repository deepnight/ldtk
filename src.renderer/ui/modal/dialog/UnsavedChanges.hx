package ui.modal.dialog;

class UnsavedChanges extends ui.modal.Dialog {
	public function new(?target:js.jquery.JQuery, after:Void->Void) {
		super(target, "unsavedChanges");

		jContent.text( L.t._("Do you want to save before leaving?") );

		addButton(L.t._("Yes"), "save", function() {
			Editor.ME.onSave(false, after);
		});

		addButton(L.t._("No"), after);

		addCancel();
	}
}