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
		jContent.find(".logPath").text( JsTools.getLogPath() );
		jContent.find( "button.viewLog").click( (_)->{
			App.LOG.flushToFile();
			var raw = NT.readFileString( JsTools.getLogPath() );
			var te = new TextEditor(raw, "LDtk logs", LangLog);
			te.scrollToEnd();
		});
		jContent.find( "button.locateLog").click( (_)->JsTools.locateFile( JsTools.getLogPath(), true ) );

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

		// Fullscreen
		var i = Input.linkToHtmlInput(settings.v.startFullScreen, jForm.find("#startFullScreen"));
		i.onValueChange = (v)->{
			ET.setFullScreen(v);
			onSettingChanged();
			App.ME.updateBodyClasses();
		}

		// Load last project
		var i = Input.linkToHtmlInput(settings.v.openLastProject, jForm.find("#openLastProject"));
		i.onValueChange = (v)->{
			if( !v )
				settings.v.lastProject = null;
			else if( Editor.exists() )
				Editor.ME.saveLastProjectInfos();
			onSettingChanged();
		}

		// Mouse wheel speed
		var i = Input.linkToHtmlInput(settings.v.mouseWheelSpeed, jForm.find("#mouseWheelSpeed"));
		i.setBounds(0.25, 3);
		i.setValueStep(0.25);
		i.enableSlider();
		i.enablePercentageMode();
		i.onChange = ()->{
			onSettingChanged();
		}

		// App scaling
		var jScale = jForm.find("#appScale");
		jScale.empty();
		for(s in [0.5, 0.75, 0.9, 1, 1.1, 1.25, 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5]) {
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
			electron.renderer.WebFrame.setZoomFactor( settings.getAppZoomFactor() );
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
		dn.Process.resizeAll();
	}
}