package ui.dialog;

class Confirm extends ui.Dialog {
	public function new(?target:js.jquery.JQuery, ?str:String, onConfirm:Void->Void) {
		super(target);

		if( str==null )
			str = L.t._("Confirm this action?");
		jContent.text(str);

		addConfirm(onConfirm);
		addCancel();
	}
}