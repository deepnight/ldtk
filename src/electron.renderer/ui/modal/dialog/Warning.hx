package ui.modal.dialog;

class Warning extends ui.modal.Dialog {
	public function new(str:dn.data.GetText.LocaleString) {
		super("warning");

		jContent.append('<h2>Warning</h2>');
		var p = '<p>' + StringTools.replace(str,"\n","</p><p>") + '</p>';
		jContent.append(p);

		addClose();
	}
}