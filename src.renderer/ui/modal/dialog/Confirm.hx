package ui.modal.dialog;

class Confirm extends ui.modal.Dialog {
	public function new(?target:js.jquery.JQuery, ?str:String, warning=false, onConfirm:Void->Void, ?onCancel:Void->Void) {
		super(target);

		jModalAndMask.addClass("confirm");

		if( warning )
			jModalAndMask.addClass("warning");

		if( str==null )
			str = L.t._("Confirm this action?");
		jContent.text(str);

		addConfirm(onConfirm);
		addCancel(onCancel);
	}
}