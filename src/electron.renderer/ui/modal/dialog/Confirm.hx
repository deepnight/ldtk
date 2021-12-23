package ui.modal.dialog;

class Confirm extends ui.modal.Dialog {
	var onConfirm : Null<Void->Void>;
	var onCancel : Null<Void->Void>;

	public function new(?target:js.jquery.JQuery, str:LocaleString, warning=false, onConfirm:Void->Void, ?onCancel:Void->Void) {
		super(target);
		this.onCancel = onCancel;
		this.onConfirm = onConfirm;

		jModalAndMask.addClass("confirm");

		if( warning )
			jModalAndMask.addClass("warning");

		if( str==null )
			str = L.t._("Confirm this action?");
		else
			str = L.untranslated( '<p>'+str.split("\n").join("</p><p>")+'</p>' );
		jContent.html(str);

		addConfirm(onConfirm);
		addCancel(onCancel);
	}

	override function onKeyPress(keyCode:Int) {
		super.onKeyPress(keyCode);
		switch keyCode {
			case K.ENTER:
				onConfirm();
				close();

			case _:
		}
	}

	override function onClickMask() {
		super.onClickMask();

		if( onCancel!=null )
			onCancel();
	}
}