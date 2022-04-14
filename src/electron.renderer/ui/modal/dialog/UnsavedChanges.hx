package ui.modal.dialog;

class UnsavedChanges extends ui.modal.Dialog {
	public function new(?target:js.jquery.JQuery, after:Void->Void, ?onCancel:Void->Void) {
		super(target, "unsavedChanges");

		jContent.text( L.t._("Do you want to save before leaving?") );

		addButton(L.t._("Yes"), "save", ()->{
			close();
			Editor.ME.onSave(after);
		});
		addButton(L.t._("No"), ()->{
			close();
			after();
		});
		addCancel( onCancel );

		#if debug
		after();
		#end
	}
}