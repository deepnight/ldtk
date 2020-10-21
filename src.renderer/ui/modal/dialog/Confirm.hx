package ui.modal.dialog;

class Confirm extends ui.modal.Dialog {
	public function new(?target:js.jquery.JQuery, ?str:String, warning=false, onConfirm:Void->Void, ?onCancel:Void->Void) {
		super(target);

		jModalAndMask.addClass("confirm");

		if( warning )
			jModalAndMask.addClass("warning");

		if( str==null )
			str = L.t._("Confirm this action?");
		else
			str = '<p>'+str.split("\n").join("</p><p>")+'</p>';
		jContent.html(str);

		addConfirm(onConfirm);
		addCancel(onCancel);
	}
}