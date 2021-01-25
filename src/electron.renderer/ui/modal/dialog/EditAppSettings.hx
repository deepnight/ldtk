package ui.modal.dialog;

class EditAppSettings extends ui.modal.Dialog {
	public function new() {
		super();

		addClose();
		updateForm();
	}

	function updateForm() {
		loadTemplate("editAppSettings", { app: Const.APP_NAME });

		var jForm = jContent.find(".form");
		jForm.off().find("*").off();

		// GPU
		var i = Input.linkToHtmlInput(settings.v.useBestGPU, jForm.find("#gpu"));
		i.onChange = ()->{
			onSettingChanged();
			N.warning(L.t._("You need to RESTART the app to apply your changes."));
		}

		// Font scaling
		var jScale = jForm.find("#fontScale");
		jScale.empty();
		for(s in [0.5, 0.75, 1, 1.5, 2, 3, 4]) {
			var jOpt = new J('<option value="$s"/>');
			jScale.append(jOpt);
			jOpt.text('${Std.int(s*100)}%');
			if( s==settings.v.editorUiScale)
				jOpt.prop("selected",true);
		}
		jScale.change( (_)->{
			settings.v.editorUiScale = Std.parseFloat( jScale.val() );
			onSettingChanged();
		});

		JsTools.parseComponents(jForm);
	}

	function hasEditor() {
		return Editor.ME!=null && !Editor.ME.destroyed;
	}

	function onSettingChanged() {
		settings.save();
		if( hasEditor() )
			Editor.ME.ge.emit( AppSettingsChanged );
		updateForm();
	}
}