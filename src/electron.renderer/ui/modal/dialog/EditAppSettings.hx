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
		// Init
		loadTemplate("editAppSettings", { app: Const.APP_NAME });
		var jForm = jContent.find(".form");
		jForm.off().find("*").off();

		// Log button
		jContent.find( "button.log").click( (_)->JsTools.exploreToFile( JsTools.getLogPath(), true ) );
		jContent.find(".logPath").text( JsTools.getLogPath() );

		// World mode using mousewheel
		var i = new form.input.EnumSelect(
			jForm.find("#autoSwitchOnZoom"),
			Settings.AutoWorldModeSwitch,
			false,
			()->settings.v.autoWorldModeSwitch,
			(v)->{
				settings.v.autoWorldModeSwitch = v;
				onSettingChanged();
			},
			(v)->return switch v {
				case Never: L.t._("Never");
				case ZoomOutOnly: L.t._("Switch when zooming out");
				case ZoomInAndOut: L.t._("Switch when zooming in or out (default)");
			}
		);

		// GPU
		var i = Input.linkToHtmlInput(settings.v.useBestGPU, jForm.find("#gpu"));
		i.onChange = ()->{
			onSettingChanged();
			needRestart = true;
		}

		// CPU throttling
		var i = Input.linkToHtmlInput(settings.v.smartCpuThrottling, jForm.find("#smartCpuThrottling"));
		i.onChange = ()->{
			onSettingChanged();
		}

		// App scaling
		var jScale = jForm.find("#appScale");
		jScale.empty();
		for(s in [0.7, 0.8, 0.9, 1, 1.1, 1.2]) {
			var jOpt = new J('<option value="$s"/>');
			jScale.append(jOpt);
			jOpt.text('${Std.int(s*100)}%');
			if( s==1 )
				jOpt.append(" "+L.t._("(default)"));
			if( s==settings.v.appUiScale)
				jOpt.prop("selected",true);
		}
		jScale.change( (_)->{
			settings.v.appUiScale = Std.parseFloat( jScale.val() );
			onSettingChanged();
			electron.renderer.WebFrame.setZoomFactor(settings.v.appUiScale);
		});

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
		anyChange = true;
		if( hasEditor() )
			Editor.ME.ge.emit( AppSettingsChanged );
		updateForm();
	}
}