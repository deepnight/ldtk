package ui.modal.dialog;

class SettingsWindow extends ui.modal.Dialog {
	public function new() {
		super();

		loadTemplate("settings", { app: Const.APP_NAME });
		addClose();

		var jForm = jContent.find(".form");
		var i = Input.linkToHtmlInput(settings.v.useBestGPU, jForm.find("#gpu"));
		i.onChange = ()->{
			settings.save();
			N.msg(L.t._("You need to close and restart LDtk for this setting to apply."));
		}
	}
}