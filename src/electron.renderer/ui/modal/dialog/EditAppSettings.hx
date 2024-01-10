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
		loadTemplate("editAppSettings", { app: Const.APP_NAME, updateVer:App.ME.pendingUpdate==null ? null : App.ME.pendingUpdate.ver });
		var jForm = jContent.find(".form");
		jForm.off().find("*").off();

		// Update available
		if( App.ME.pendingUpdate==null )
			jContent.find(".update").hide();
		else {
			jContent.find(".update").click(_->{
				if( App.ME.pendingUpdate.github ) {
					App.ME.checkForUpdate();
				}
				else
					electron.Shell.openExternal(Const.DOWNLOAD_URL);
				close();
			});
		}

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

		// Auto update
		var i = Input.linkToHtmlInput(settings.v.autoInstallUpdates, jForm.find("#autoUpdate"));
		i.onChange = ()->{
			onSettingChanged();
			needRestart = true;
		}
		i.setEnabled( NT.isWindows() );
		var jUnsupported = jForm.find("#autoUpdate").siblings(".unsupported");
		if( NT.isWindows() )
			jUnsupported.hide();
		else
			jUnsupported.show();

		// Fullscreen
		var i = Input.linkToHtmlInput(settings.v.startFullScreen, jForm.find("#startFullScreen"));
		i.onValueChange = (v)->{
			ET.setFullScreen(v);
			onSettingChanged();
			App.ME.updateBodyClasses();
		}

		// Single layer mode intensity
		var allValues = [0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1];
		if( !allValues.contains(settings.v.singleLayerModeIntensity) ) {
			for(v in allValues)
				if( v>=settings.v.singleLayerModeIntensity) {
					settings.v.singleLayerModeIntensity = v;
					break;
				}
		}
		JsTools.createValuesSelect(
			jForm.find("#singleLayerModeIntensity"),
			settings.v.singleLayerModeIntensity,
			allValues,
			false,
			0.9,
			(v)->Std.string(v*100)+"%",
			(v)->{
				settings.v.singleLayerModeIntensity = v;
				onSettingChanged();
			}
		);

		// Nearby tiles rendering distance
		var allValues = [0, 1, 1.5, 2];
		if( !allValues.contains(settings.v.nearbyTilesRenderingDist) ) {
			for(v in allValues)
				if( v>=settings.v.nearbyTilesRenderingDist) {
					settings.v.nearbyTilesRenderingDist = v;
					break;
				}
		}
		JsTools.createValuesSelect(
			jForm.find("#nearbyTilesRenderingDist"),
			settings.v.nearbyTilesRenderingDist,
			allValues,
			false,
			1,
			(v)->switch v {
				case 0: "Disabled";
				case _: settings.getNearbyTilesRenderingDistPx(v)+" pixels";
			},
			(v)->{
				settings.v.nearbyTilesRenderingDist = v;
				onSettingChanged();
			}
		);

		// Load last project
		var i = Input.linkToHtmlInput(settings.v.openLastProject, jForm.find("#openLastProject"));
		i.onValueChange = (v)->{
			if( !v )
				settings.v.lastProject = null;
			else if( Editor.exists() )
				Editor.ME.saveLastProjectInfos();
			onSettingChanged();
		}

		// Color blind
		var i = Input.linkToHtmlInput(settings.v.colorBlind, jForm.find("#colorBlind"));
		i.onChange = ()->onSettingChanged();

		// Blur mask
		var i = Input.linkToHtmlInput(settings.v.blurMask, jForm.find("#blurMask"));
		i.onChange = ()->onSettingChanged();

		// Fields render
		var jSelect = jForm.find("#fieldsRender");
		jSelect.empty();
		for(k in Settings.FieldsRender.getConstructors()) {
			var nk = Settings.FieldsRender.createByName(k);
			var jOpt = new J('<option value="$k"/>');
			jSelect.append(jOpt);
			jOpt.text(switch nk {
				case FR_Outline: L.t._("Outlined texts (default)");
				case FR_Table: L.t._("Opaque tables");
			});
			if( settings.v.fieldsRender==nk )
				jOpt.prop("selected",true);
		}
		jSelect.change( (_)->{
			settings.v.fieldsRender = FieldsRender.createByName( jSelect.val() );
			onSettingChanged();
		});

		// Navigation keys
		var jNavKeys = jForm.find("#navKeys");
		jNavKeys.empty();
		for(k in Settings.NavigationKeys.getConstructors()) {
			var nk = Settings.NavigationKeys.createByName(k);
			var jOpt = new J('<option value="$k"/>');
			jNavKeys.append(jOpt);
			jOpt.text(k.toUpperCase());
			if( nk==settings.v.navigationKeys )
				jOpt.prop("selected",true);
		}
		jNavKeys.change( (_)->{
			settings.v.navigationKeys = Settings.NavigationKeys.createByName( jNavKeys.val() );
			onSettingChanged();
		});

		// Mouse wheel speed
		var i = Input.linkToHtmlInput(settings.v.mouseWheelSpeed, jForm.find("#mouseWheelSpeed"));
		i.setBounds(0.25, 3);
		i.enablePercentageMode();
		i.onChange = ()->{
			onSettingChanged();
		}

		// App scaling
		var jScale = jForm.find("#appScale");
		jScale.empty();
		for(s in [0.5, 0.6, 0.7, 0.8, 0.9, 1, 1.1, 1.2, 1.3, 1.4, 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5]) {
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
		for(s in [0.5, 0.6, 0.7, 0.8, 0.9, 1, 1.1, 1.2, 1.3, 1.4, 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5]) {
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