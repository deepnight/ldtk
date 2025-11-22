package ui.modal.dialog;

import dn.data.LocaleString;

class Warning extends ui.modal.Dialog {
	public function new(str:LocaleString) {
		super("warning");

		jContent.append('<h2>Warning</h2>');
		var p = '<p>' + StringTools.replace(str,"\n","</p><p>") + '</p>';
		jContent.append(p);

		addClose();
	}
}