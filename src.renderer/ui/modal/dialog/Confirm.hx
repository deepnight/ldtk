package ui.modal.dialog;

class Confirm extends ui.modal.Dialog {
	var onCancel : Null<Void->Void>;

	public function new(?target:js.jquery.JQuery, ?str:String, warning=false, onConfirm:Void->Void, ?onCancel:Void->Void) {
		super(target);
		this.onCancel = onCancel;

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

	override function onClickMask() {
		if( onCancel!=null )
			onCancel();
		super.onClickMask();
	}
}