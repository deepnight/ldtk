package ui.modal.panel;

class EditProject extends ui.modal.Panel {

	var showAdvanced = false;
	var allAdvancedOptions = [
		ldtk.Json.ProjectFlag.DiscardPreCsvIntGrid,
	];

	public function new() {
		super();

		loadTemplate("editProject", "editProject", {
			app: Const.APP_NAME,
			ext: Const.FILE_EXTENSION,
		});
		linkToButton("button.editProject");

		showAdvanced = project.hasAnyFlag(allAdvancedOptions);

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


		var jRename = jContent.find("button.rename").click( function(ev) {
			new ui.modal.dialog.InputDialog(
				L.t._("Enter the new project file name :"),
				project.filePath.fileName,
				project.filePath.extWithDot,
				(str)->{
					if( str==null || str.length==0 )
						return L.t._("Invalid file name");

					var clean = dn.FilePath.cleanUp(str, true);
					if( clean.length==0 )
						return L.t._("Invalid file name");

					if( project.filePath.fileName==str )
						return L.t._("Enter a new project file name.");

					var newPath = project.filePath.directoryWithSlash + str + project.filePath.extWithDot;
					if( NT.fileExists(newPath) )
						return L.t._("This file name is already in use.");

					return null;
				},
				(str)->{
					return dn.FilePath.cleanUpFileName(str);
				},
				(fileName)->{
					// Rename project
					App.LOG.fileOp('Renaming project: ${project.filePath.fileName} -> $fileName');
					try {
						// Rename project file
						App.LOG.fileOp('  Renaming project file...');
						var oldProjectPath = project.filePath.full;
						var oldExtDir = project.getAbsExternalFilesDir();
						project.filePath.fileName = fileName;

						// Rename sub dir
						if( NT.fileExists(oldExtDir) ) {
							App.LOG.fileOp('  Renaming project sub dir...');
							NT.renameFile(oldExtDir, project.getAbsExternalFilesDir());
						}

						// Re-save project
						editor.invalidateAllLevelsCache();
						App.LOG.fileOp('  Saving project...');
						new ui.ProjectSaver(this, project, (success)->{
							// Remove old project file
							App.LOG.fileOp('  Deleting old project file...');
							NT.removeFile(oldProjectPath);
							App.ME.unregisterRecentProject(oldProjectPath);

							// Success!
							N.success("Renamed project!");
							editor.needSaving = false;
							editor.updateTitle();
							App.ME.registerRecentProject(editor.project.filePath.full);
							App.LOG.fileOp('  Done.');
						});
					}
				}
			);
		});
		if( project.isBackup() )
			jRename.hide();

		jContent.find("button.locate").click( function(ev) {
			ET.locate( project.filePath.full, true );
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
		var jForm = jContent.find("dl.form:first");
		jForm.off().find("*").off();

		// File extension
		var ext = project.filePath.extension;
		var usesAppDefault = ext==Const.FILE_EXTENSION;
		var i = Input.linkToHtmlInput( usesAppDefault, jForm.find("[name=useAppExtension]") );
		i.onValueChange = (v)->{
			var old = project.filePath.full;
			var fp = project.filePath.clone();
			fp.extension = v ? Const.FILE_EXTENSION : "json";
			if( NT.fileExists(old) && NT.renameFile(old, fp.full) ) {
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
		jForm.find(".backupRecommend").css("visibility", project.recommendsBackup() ? "visible" : "hidden");


		// Json minifiying
		var i = Input.linkToHtmlInput( project.minifyJson, jForm.find("[name=minify]") );
		i.linkEvent(ProjectSettingsChanged);

		// External level files
		jForm.find(".externRecommend").css("visibility", project.levels.length>=10 && !project.externalLevels ? "visible" : "hidden");
		var i = Input.linkToHtmlInput( project.externalLevels, jForm.find("#externalLevels") );
		i.linkEvent(ProjectSettingsChanged);
		var jLocate = jForm.find("#externalLevels").siblings(".locate").empty();
		if( project.externalLevels )
			jLocate.append( JsTools.makeExploreLink(project.getAbsExternalFilesDir(), false) );

		// Image export
		var jImgExport = jForm.find(".imageExportMode");
		var jSelect = jImgExport.find("select");
		var i = new form.input.EnumSelect(
			jSelect,
			ldtk.Json.ImageExportMode,
			()->project.imageExportMode,
			(v)->{
				project.pngFilePattern = null;
				project.imageExportMode = v;
			},
			(v)->switch v {
				case None: L.t._("Don't export any image");
				case OneImagePerLayer: L.t._("Export one PNG for each individual layer, in each level");
				case OneImagePerLevel: L.t._("Export a single PNG per level (all layers are merged down)");
			}
		);
		i.linkEvent(ProjectSettingsChanged);
		var jLocate = jImgExport.find(".locate").empty();
		var jFilePattern : js.jquery.JQuery = jImgExport.find(".pattern").hide();
		var jExample : js.jquery.JQuery = jImgExport.find(".example").hide();
		var jReset : js.jquery.JQuery = jImgExport.find(".reset").hide();
		if( project.imageExportMode!=None ) {
			jFilePattern.show();
			jExample.show();
			jReset.show();
			jReset.click( (_)->{
				project.pngFilePattern = null;
				editor.ge.emit(ProjectSettingsChanged);
			});
			jLocate.append( JsTools.makeExploreLink(project.getAbsExternalFilesDir()+"/png", false) );

			var i = new form.input.StringInput(
				jFilePattern,
				()->project.getImageExportFilePattern(),
				(v)->{
					project.pngFilePattern = v==project.getDefaultImageExportFilePattern() ? null : v;
					editor.ge.emit(ProjectSettingsChanged);
				}
			);
			jFilePattern.keyup( (_)->{
				var pattern = jFilePattern.val()==null ? project.getDefaultImageExportFilePattern() : jFilePattern.val();
				jExample.text( '"'+project.getPngFileName(pattern, editor.curLevel, editor.curLayerDef)+'.png"' );
			} ).keyup();
		}


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

		// Level name pattern
		var i = Input.linkToHtmlInput( project.levelNamePattern, jForm.find("input.levelNamePattern") );
		i.linkEvent(ProjectSettingsChanged);
		i.onChange = ()->project.tidy();


		// Advanced options
		var jAdvanceds = jForm.find(".adv");
		if( showAdvanced ) {
			jForm.find("a.showAdv").hide();
			jAdvanceds.show();
		}
		else {
			jForm.find("a.showAdv").show().click(ev->{
				jAdvanceds.show();
				showAdvanced = true;
				ev.getThis().hide();
			});
			jAdvanceds.hide();
		}
		var jAdvancedFlags = jAdvanceds.find("ul.advFlags");
		jAdvancedFlags.empty();
		for( e in allAdvancedOptions ) {
			var jLi = new J('<li/>');
			jLi.appendTo(jAdvancedFlags);

			var jInput = new J('<input type="checkbox" id="$e"/>');
			jInput.appendTo(jLi);

			var jLabel = new J('<label for="$e"/>');
			jLabel.appendTo(jLi);
			switch e {
				case DiscardPreCsvIntGrid:
					jLabel.text("Discard pre-CSV IntGrid layer data in level data");
					jInput.attr("title", L.t._("If enabled, the exported JSON will not contain the deprecated array \"intGrid\", making the file smaller. Only use this if your game API supports LDtk 0.8.x or more."));
				case _:
			}

			var i = new form.input.BoolInput(
				jInput,
				()->project.hasFlag(e),
				(v)->{
					project.setFlag(e, v);
					editor.ge.emit(ProjectSettingsChanged);
				}
			);
		}

		JsTools.parseComponents(jForm);
		checkBackup();
	}
}
