package ui.modal.panel;

class EditProject extends ui.modal.Panel {

	public function new() {
		super();

		loadTemplate("editProject", "editProject", {
			app: Const.APP_NAME,
			ext: Const.FILE_EXTENSION,
		});
		linkToButton("button.editProject");

		var jSave = jContent.find("button.save").click( function(ev) {
			editor.onSave();
			if( project.isBackup() )
				close();
		});
		if( project.isBackup() )
			jSave.text(L.t._("Restore this backup"));

		var jSaveAs = jContent.find("button.saveAs").click( function(ev) {
			editor.onSave(true);
		});
		if( project.isBackup() )
			jSaveAs.hide();

		jContent.find("button.locate").click( function(ev) {
			JsTools.exploreToFile(project.filePath.full, true);
		});

		if( !project.isBackup() )
			jContent.find("button.settings").click( function(ev) {
				close();
				new ui.modal.dialog.EditAppSettings();
			});

		updateProjectForm();
	}

	override function onGlobalEvent(ge:GlobalEvent) {
		super.onGlobalEvent(ge);
		switch( ge ) {
			case ProjectSettingsChanged:
				updateProjectForm();

			case _:
		}
	}

	function updateProjectForm() {
		ui.Tip.clear();
		var jForm = jContent.find("ul.form:first");

		// File extension
		var ext = project.filePath.extension;
		var usesAppDefault = ext==Const.FILE_EXTENSION;
		var i = Input.linkToHtmlInput( usesAppDefault, jForm.find("[name=useAppExtension]") );
		i.onValueChange = (v)->{
			var old = project.filePath.full;
			var fp = project.filePath.clone();
			fp.extension = v ? Const.FILE_EXTENSION : "json";
			if( JsTools.fileExists(old) && JsTools.renameFile(old, fp.full) ) {
				App.ME.renameRecentProject(old, fp.full);
				project.filePath.parseFilePath(fp.full);
				N.success(L.t._("Changed file extension to ::ext::", { ext:fp.extWithDot }));
			}
			else {
				N.error(L.t._("Couldn't rename project file!"));
			}
		}

		// Backups
		var i = Input.linkToHtmlInput( project.backupOnSave, jForm.find("#backup") );
		i.linkEvent(ProjectSettingsChanged);
		var jLocate = i.jInput.siblings(".locate").empty();
		if( project.backupOnSave )
			jLocate.append( JsTools.makeExploreLink(project.getAbsExternalFilesDir()+"/backups", false) );
		var jCount = jForm.find("#backupCount");
		jCount.val( Std.string(Const.DEFAULT_BACKUP_LIMIT) );
		if( project.backupOnSave ) {
			jCount.show();
			jCount.siblings("span").show();
			var i = Input.linkToHtmlInput( project.backupLimit, jCount );
			i.setBounds(3, 50);
		}
		else {
			jCount.hide();
			jCount.siblings("span").hide();
		}


		// Json minifiying
		var i = Input.linkToHtmlInput( project.minifyJson, jForm.find("[name=minify]") );
		i.linkEvent(ProjectSettingsChanged);

		// External level files
		var i = Input.linkToHtmlInput( project.externalLevels, jForm.find("#externalLevels") );
		i.linkEvent(ProjectSettingsChanged);
		var jLocate = jForm.find("#externalLevels").siblings(".locate").empty();
		if( project.externalLevels )
			jLocate.append( JsTools.makeExploreLink(project.getAbsExternalFilesDir(), false) );

		// Png export
		var i = Input.linkToHtmlInput( project.exportPng, jForm.find("#png") );
		i.linkEvent(ProjectSettingsChanged);
		var jLocate = jForm.find("#png").siblings(".locate").empty();
		if( project.exportPng )
			jLocate.append( JsTools.makeExploreLink(project.getAbsExternalFilesDir()+"/png", false) );

		// Tiled export
		var i = Input.linkToHtmlInput( project.exportTiled, jForm.find("#tiled") );
		i.linkEvent(ProjectSettingsChanged);
		i.onValueChange = function(v) {
			if( v )
				new ui.modal.dialog.Message(Lang.t._("Disclaimer: Tiled export is only meant to load your LDtk project in a game framework that only supports Tiled files. It is recommended to write your own LDtk JSON parser, as some LDtk features may not be supported.\nIt's not so complicated, I promise :)"), "project");
		}
		var jLocate = jForm.find("#tiled").siblings(".locate").empty();
		if( project.exportTiled )
			jLocate.append( JsTools.makeExploreLink(project.getAbsExternalFilesDir()+"/tiled", false) );

		// Level grid size
		var i = Input.linkToHtmlInput( project.defaultGridSize, jForm.find("[name=defaultGridSize]") );
		i.setBounds(1,Const.MAX_GRID_SIZE);
		i.linkEvent(ProjectSettingsChanged);

		// Workspace bg
		var i = Input.linkToHtmlInput( project.bgColor, jForm.find("[name=bgColor]"));
		i.isColorCode = true;
		i.linkEvent(ProjectSettingsChanged);

		// Level bg
		var i = Input.linkToHtmlInput( project.defaultLevelBgColor, jForm.find("[name=defaultLevelbgColor]"));
		i.isColorCode = true;
		i.linkEvent(ProjectSettingsChanged);

		// Default entity pivot
		var pivot = jForm.find(".pivot");
		pivot.empty();
		pivot.append( JsTools.createPivotEditor(
			project.defaultPivotX, project.defaultPivotY,
			0x0,
			function(x,y) {
				project.defaultPivotX = x;
				project.defaultPivotY = y;
				editor.ge.emit(ProjectSettingsChanged);
			}
		));

		JsTools.parseComponents(jForm);
	}
}
