package ui.modal.dialog;

class EditAppSettings extends ui.modal.Dialog {
	var anyChange = false;
	var needRestart = false;

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
			needRestart = true;
		}

		// Font scaling
		var jScale = jForm.find("#fontScale");
		jScale.empty();
		for(s in [0.5, 0.75, 1, 1.25, 1.5, 2, 3, 4]) {
			var jOpt = new J('<option value="$s"/>');
			jScale.append(jOpt);
			jOpt.text('${Std.int(s*100)}%');
			if( s==1 )
				jOpt.append(" "+L.t._("(default)"));
			if( s==settings.v.editorUiScale)
				jOpt.prop("selected",true);
		}
		jScale.change( (_)->{
			settings.v.editorUiScale = Std.parseFloat( jScale.val() );
			onSettingChanged();
		});

		JsTools.parseComponents(jForm);
	}

	override function onClose() {
		super.onClose();

		if( needRestart )
			N.warning( L.t._("Saved. You need to RESTART the app to apply your changes.") );
		else if( anyChange )
			N.success( L.t._("Settings saved.") );
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