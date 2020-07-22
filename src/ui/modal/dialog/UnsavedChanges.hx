package ui.modal.dialog;

class UnsavedChanges extends ui.modal.Dialog {
	public function new(?target:js.jquery.JQuery, onIgnore:Void->Void) {
		super(target, "unsavedChanges");

		jContent.text( L.t._("Some changes were not saved and will be lost forever if you do that!") );

		addButton(L.t._("Ignore and continue"), "ignore", onIgnore);
		addCancel();
	}
}