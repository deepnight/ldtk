package ui.modal.panel;

class EditProject extends ui.modal.Panel {

	var showAdvanced = false;
	var allAdvancedOptions = [
		ldtk.Json.ProjectFlag.MultiWorlds,
		ldtk.Json.ProjectFlag.PrependIndexToLevelFileNames,
		ldtk.Json.ProjectFlag.ExportPreCsvIntGridFormat,
		ldtk.Json.ProjectFlag.UseMultilinesType,
		ldtk.Json.ProjectFlag.ExportOldTableOfContentData,
	];

	var levelNamePatternEditor : NamePatternEditor;
	var pngPatternEditor : ui.NamePatternEditor;

	public function new() {
		super();

		loadTemplate("editProject", "editProject", {
			app: Const.APP_NAME,
			ext: Const.FILE_EXTENSION,
		});
		linkToButton("button.editProject");

		showAdvanced = project.hasAnyFlag(allAdvancedOptions);

		var jSave = jContent.find("button.save").click( function(ev) {
			App.ME.executeAppCommand(C_SaveProject);
			if( project.isBackup() )
				close();
		});
		if( project.isBackup() )
			jSave.text(L.t._("Restore this backup"));

		var jSaveAs = jContent.find("button.saveAs").click( _->App.ME.executeAppCommand(C_SaveProjectAs) );
		if( project.isBackup() )
			jSaveAs.hide();


		var jRename = jContent.find("button.rename").click( _->App.ME.executeAppCommand(C_RenameProject) );
		if( project.isBackup() )
			jRename.hide();

		jContent.find("button.locate").click( function(ev) {
			JsTools.locateFile( project.filePath.full, true );
		});

		pngPatternEditor = new ui.NamePatternEditor(
			"png",
			project.getImageExportFilePattern(),
			[
				{ k:"world", displayName:"WorldName" },
				{ k:"level_name", displayName:"LevelName" },
				{ k:"level_idx", displayName:"LevelIdx" },
				{ k:"layer_name", displayName:"LayerName" },
				{ k:"layer_idx", displayName:"LayerIdx" },
			],
			(pat)->{
				project.pngFilePattern = pat==project.getDefaultImageExportFilePattern() ? null : pat;
				editor.ge.emit(ProjectSettingsChanged);
			},
			()->{
				project.pngFilePattern = null;
				editor.ge.emit(ProjectSettingsChanged);
			}
		);
		jContent.find(".pngPatternEditor").empty().append( pngPatternEditor.jEditor );

		levelNamePatternEditor = new ui.NamePatternEditor(
			"levelId",
			project.levelNamePattern,
			[
				{ k:"world", displayName:"WorldId" },
				{ k:"idx1", displayName:"LevelIndex(1)", desc:"Level index (starting at 1)" },
				{ k:"idx", displayName:"LevelIndex(0)", desc:"Level index (starting at 0)" },
				{ k:"x", displayName:"LevelX", desc:"X coordinate of the level" },
				{ k:"y", displayName:"LevelY", desc:"Y coordinate of the level" },
				{ k:"gx", displayName:"GridX", desc:"X grid coordinate of the level" },
				{ k:"gy", displayName:"GridY", desc:"Y grid coordinate of the level" },
				{ k:"depth", displayName:"WorldDepth", desc:"Level depth in the world" },
			],
			(pat)->{
				project.levelNamePattern = pat;
				editor.ge.emit(ProjectSettingsChanged);
				editor.invalidateAllLevelsCache();
				project.tidy();
			},
			()->{
				if( project.levelNamePattern!=data.Project.DEFAULT_LEVEL_NAME_PATTERN ) {
					project.levelNamePattern = data.Project.DEFAULT_LEVEL_NAME_PATTERN;
					editor.ge.emit(ProjectSettingsChanged);
					editor.invalidateAllLevelsCache();
					project.tidy();
					N.success("Value reset.");
				}
			}
		);
		jContent.find(".levelNamePatternEditor").empty().append( levelNamePatternEditor.jEditor );

		updateProjectForm();
	}

	override function onGlobalEvent(ge:GlobalEvent) {
		super.onGlobalEvent(ge);
		switch( ge ) {
			case ProjectSettingsChanged:
				updateProjectForm();

			case ProjectSaved:
				updateProjectForm();

			case _:
		}
	}

	function recommendSaving() {
		if( !cd.hasSetS("saveReco",2) )
			N.warning(
				L.t._("Project file setting changed"),
				L.t._("You should save the project at least once for this setting to apply its effects.")
			);
	}

	function updateProjectForm() {
		ui.Tip.clear();
		var jForms = jContent.find("dl.form");
		jForms.off().find("*").off();

		// Simplified format adjustments
		if( project.simplifiedExport )
			jForms.find(".notSimplified").hide();
		else
			jForms.find(".notSimplified").show();

		// File extension
		var ext = project.filePath.extension;
		var usesAppDefault = ext==Const.FILE_EXTENSION;
		var i = Input.linkToHtmlInput( usesAppDefault, jForms.find("[name=useAppExtension]") );
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
		var i = Input.linkToHtmlInput( project.backupOnSave, jForms.find("#backup") );
		i.linkEvent(ProjectSettingsChanged);
		var jLocate = i.jInput.siblings(".locate").empty();
		if( project.backupOnSave )
			jLocate.append( JsTools.makeLocateLink(project.getAbsBackupDir(), false) );
		var jCount = jForms.find("#backupCount");
		var jBackupPath = jForms.find(".curBackupPath");
		var jResetBackup = jForms.find(".resetBackupPath");
		jCount.val( Std.string(Const.DEFAULT_BACKUP_LIMIT) );
		if( project.backupOnSave ) {
			jBackupPath.show();

			jCount.show();
			jCount.siblings("span").show();
			var i = Input.linkToHtmlInput( project.backupLimit, jCount );
			i.setBounds(3, 50);
			i.linkEvent(ProjectSettingsChanged);

			jBackupPath.text( project.backupRelPath==null ? "[Default dir]" : "[Custom dir]" );
			if( project.backupRelPath==null )
				jBackupPath.removeAttr("title");
			else
				jBackupPath.attr("title", project.backupRelPath);

			jBackupPath.click(_->{
				var absPath = project.getAbsBackupDir();
				if( !NT.fileExists(absPath) )
					absPath = project.filePath.full;

				dn.js.ElectronDialogs.openDir(absPath, (dirPath)->{
					var fp = dn.FilePath.fromDir(dirPath);
					fp.useSlashes();
					fp.makeRelativeTo(project.filePath.directory);
					project.backupRelPath = fp.full;
					editor.ge.emit(ProjectSettingsChanged);
				});
			});
			jResetBackup.find(".reset");
			if( project.backupRelPath==null )
				jResetBackup.hide();
			else
				jResetBackup.show().click( (ev:js.jquery.Event)->{
					ev.preventDefault();
					project.backupRelPath = null;
					editor.ge.emit(ProjectSettingsChanged);
				});
		}
		else {
			jCount.hide();
			jCount.siblings("span").hide();
			jBackupPath.hide();
			jResetBackup.hide();
		}
		jForms.find(".backupRecommend").css("visibility", project.recommendsBackup() ? "visible" : "hidden");


		// Json minifiying
		var i = Input.linkToHtmlInput( project.minifyJson, jForms.find("[name=minify]") );
		i.linkEvent(ProjectSettingsChanged);
		i.onChange = ()->{
			editor.invalidateAllLevelsCache;
			recommendSaving();
		}

		// Simplified format
		var i = Input.linkToHtmlInput( project.simplifiedExport, jForms.find("[name=simplifiedExport]") );
		i.onChange = ()->{
			editor.invalidateAllLevelsCache();
			editor.ge.emit(ProjectSettingsChanged);
			if( project.simplifiedExport )
				recommendSaving();
		}
		var jLocate = jForms.find(".simplifiedExport .locate").empty();
		if( project.simplifiedExport )
			jLocate.append(
				NT.fileExists( project.getAbsExternalFilesDir() )
					? JsTools.makeLocateLink(project.getAbsExternalFilesDir()+"/simplified", false)
					: JsTools.makeLocateLink(project.filePath.full, true)
			);

		// External level files
		var i = Input.linkToHtmlInput( project.externalLevels, jForms.find("#externalLevels") );
		i.linkEvent(ProjectSettingsChanged);
		i.onValueChange = (v)->{
			editor.invalidateAllLevelsCache();
			recommendSaving();
		}
		var jLocate = jForms.find("#externalLevels").siblings(".locate").empty();
		if( project.externalLevels )
			jLocate.append( JsTools.makeLocateLink(project.getAbsExternalFilesDir(), false) );

		// Image export
		var jImgExport = jForms.find(".imageExportMode");
		var jSelect = jImgExport.find("select");
		var i = new form.input.EnumSelect(
			jSelect,
			ldtk.Json.ImageExportMode,
			()->project.imageExportMode,
			(v)->{
				project.pngFilePattern = null;
				project.imageExportMode = v;
				if( v!=None )
					recommendSaving();
			},
			(v)->switch v {
				case None: L.t._("Don't export any image");
				case OneImagePerLayer: L.t._("One PNG per layer");
				case OneImagePerLevel: L.t._("One PNG per level (layers are merged down)");
				case LayersAndLevels: L.t._("One PNG per layer and one per level.");
			}
		);
		i.linkEvent(ProjectSettingsChanged);
		var jLocate = jImgExport.find(".locate").empty();
		pngPatternEditor.jEditor.hide();
		jForms.find(".imageExportOnly").hide();
		if( project.imageExportMode!=None && !project.simplifiedExport ) {
			jForms.find(".imageExportOnly").show();
			jLocate.append( JsTools.makeLocateLink(project.getAbsExternalFilesDir()+"/png", false) );

			pngPatternEditor.jEditor.show();
			pngPatternEditor.ofString( project.getImageExportFilePattern() );
		}

		var i = Input.linkToHtmlInput(project.exportLevelBg, jForms.find("#exportLevelBg"));
		i.linkEvent(ProjectSettingsChanged);


		// Identifier style
		var i = new form.input.EnumSelect(
			jForms.find("#identifierStyle"),
			ldtk.Json.IdentifierStyle,
			false,
			()->return project.identifierStyle,
			(v)->{
				if( v==project.identifierStyle )
					return;

				var old = project.identifierStyle;
				new LastChance(L.t._("Identifier style changed"), project);
				project.identifierStyle = v;
				project.applyIdentifierStyleEverywhere(old);
				editor.invalidateAllLevelsCache();
				editor.ge.emit(ProjectSettingsChanged);
			},
			(v)->switch v {
				case Capitalize: L.t._('"My_identifier_1" -- First letter is always uppercase, the rest is up to you');
				case Uppercase: L.t._('"MY_IDENTIFIER_1" -- Full uppercase');
				case Lowercase: L.t._('"my_identifier_1" -- Full lowercase');
				case Free: L.t._('"my_IdEnTifIeR_1" -- I wON\'t cHaNge yOuR leTteR caSe');
			}
		);
		i.customConfirm = (oldV,newV)->{
			switch newV {
				case Capitalize, Uppercase, Lowercase:
					L.t._("WARNING!\nPlease make sure the game engine or importer you're using supports this kind of LDtk identifier!\nIf you proceed, all identifiers in this project will be converted to the new format!\nAre you sure?");

				case Free:
					L.t._("WARNING!\nPlease make sure the game engine or importer you're using supports this kind of LDtk identifier!\nAre you sure?");
			}
		}
		var jStyleWarning = jForms.find("#styleWarning");
		switch project.identifierStyle {
			case Capitalize, Uppercase: jStyleWarning.hide();
			case Lowercase, Free: jStyleWarning.show();
		}

		// Tiled export
		var i = Input.linkToHtmlInput( project.exportTiled, jForms.find("#tiled") );
		i.linkEvent(ProjectSettingsChanged);
		i.onValueChange = function(v) {
			if( v ) {
				new ui.modal.dialog.Message(
					Lang.t._("Disclaimer: Tiled export is only meant to load your LDtk project in a game framework that only supports Tiled files. It is recommended to write your own LDtk JSON parser, as some LDtk features may not be supported.\nIt's not so complicated, I promise :)"), "project",
					()->recommendSaving()
				);
			}
		}
		var jLocate = jForms.find("#tiled").siblings(".locate").empty();
		if( project.exportTiled )
			jLocate.append( JsTools.makeLocateLink(project.getAbsExternalFilesDir()+"/tiled", false) );


		// Custom commands
		var jCommands = jForms.find(".customCommands");
		jCommands.find("ul").empty();
		function _createCommandJquery(cmd:ldtk.Json.CustomCommand) {
			var jCmd = jCommands.find("xml#customCommand").children().clone(false, false).wrapAll("<li/>").parent();
			jCmd.appendTo( jCommands.find("ul") );
			Input.linkToHtmlInput(cmd.command, jCmd.find(".command"));
			new form.input.EnumSelect(
				jCmd.find("select.when"),
				ldtk.Json.CustomCommandTrigger,
				false,
				()->cmd.when,
				(v)->cmd.when = v,
				(v)->switch v {
					case Manual: App.isMac() ? L.t._("Run manually (CMD-R)") : L.t._("Run manually (CTRL-R)");
					case AfterLoad: L.t._("Run after loading");
					case BeforeSave: L.t._("Run before saving");
					case AfterSave: L.t._("Run after saving");
				}
			);
			var jRem = jCmd.find("button.remove");
			jRem.click(_->{
				function _removeCmd() {
					project.customCommands.remove(cmd);
					editor.ge.emit(ProjectSettingsChanged);
				}
				if( cmd.command=="" )
					_removeCmd();
				else
					new ui.modal.dialog.Confirm(jRem, L.t._("Are you sure?"), ()->{
						new LastChance(L.t._("Project command removed"), project);
						_removeCmd();
					});
			});
		}
		var jAdd = jCommands.find("button.add");
		jAdd.off().click( _->{
			var cmd : ldtk.Json.CustomCommand = { command:"", when:Manual }
			project.customCommands.push(cmd);
			editor.ge.emit(ProjectSettingsChanged);
		});
		for( cmd in project.customCommands )
			_createCommandJquery(cmd);
		JsTools.makeSortable(jCommands.find("ul"), (ev:sortablejs.Sortable.SortableDragEvent)->{
			var from = ev.oldIndex;
			var to = ev.newIndex;

			if( from<0 || from>=project.customCommands.length || from==to )
				return;

			if( to<0 || to>=project.customCommands.length )
				return;

			var moved = project.customCommands.splice(from,1)[0];
			project.customCommands.insert(to, moved);
			editor.ge.emit( ProjectSettingsChanged );
		});

		// Commands trust
		if( settings.isProjectTrusted(project.iid) )
			jCommands.find(".untrusted").hide();
		else if( settings.isProjectUntrusted(project.iid) )
			jCommands.find(".trusted").hide();
		else {
			jCommands.find(".untrusted").hide();
			jCommands.find(".trusted").hide();
		}
		jCommands.find(".trusted a, .untrusted a").click(_->{
			settings.clearProjectTrust(project.iid);
			editor.ge.emit( ProjectSettingsChanged );
		});


		// Level grid size
		var i = Input.linkToHtmlInput( project.defaultGridSize, jForms.find("[name=defaultGridSize]") );
		i.setBounds(1,Const.MAX_GRID_SIZE);
		i.linkEvent(ProjectSettingsChanged);


		// Default entity size
		var i = Input.linkToHtmlInput( project.defaultEntityWidth, jForms.find("[name=defaultEntityWidth]") );
		i.setBounds(1,Const.MAX_GRID_SIZE);
		i.linkEvent(ProjectSettingsChanged);

		var i = Input.linkToHtmlInput( project.defaultEntityHeight, jForms.find("[name=defaultEntityHeight]") );
		i.setBounds(1,Const.MAX_GRID_SIZE);
		i.linkEvent(ProjectSettingsChanged);

		// Workspace bg
		var i = Input.linkToHtmlInput( project.bgColor, jForms.find("[name=bgColor]"));
		i.linkEvent(ProjectSettingsChanged);

		// Level bg
		var i = Input.linkToHtmlInput( project.defaultLevelBgColor, jForms.find("[name=defaultLevelbgColor]"));
		i.onChange = ()->{
			for(w in project.worlds)
			for(l in w.levels)
				if( l.isUsingDefaultBgColor() )
					editor.ge.emit(LevelSettingsChanged(l));
		}
		i.linkEvent(ProjectSettingsChanged);

		// Default entity pivot
		var pivot = jForms.find(".pivot");
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
		levelNamePatternEditor.ofString(project.levelNamePattern);

		// Advanced options
		var jAdvanceds = jForms.filter(".advanced");
		if( showAdvanced ) {
			jContent.find(".collapser.collapsed").click();
			// jForms.find("a.showAdv").hide();
			// jAdvanceds.addClass("visible");
		}
		else {
			// jForms.find("a.showAdv").show().click(ev->{
			// 	jAdvanceds.addClass("visible");
			// 	showAdvanced = true;
			// 	jWrapper.scrollTop( jWrapper.innerHeight() );
			// 	ev.getThis().hide();
			// });
		}
		var jAdvancedFlags = jAdvanceds.find("ul.advFlags");
		jAdvancedFlags.empty();
		for( flag in allAdvancedOptions ) {
			var jLi = new J('<li/>');
			jLi.appendTo(jAdvancedFlags);

			var jInput = new J('<input type="checkbox" id="$flag"/>');
			jInput.appendTo(jLi);

			var jLabel = new J('<label for="$flag"/>');
			jLabel.appendTo(jLi);
			var jDesc = new J('<div class="desc"/>');
			jDesc.appendTo(jLi);
			inline function _setDesc(str) {
				jDesc.html('<p>'+str.split("\n").join("</p><p>")+'</p>');
			}
			switch flag {
				case ExportPreCsvIntGridFormat:
					jLabel.text("Export legacy pre-CSV IntGrid layers data");
					_setDesc( L.t._("If enabled, the exported JSON file will also contain the now deprecated array \"intGrid\". The file will be significantly larger.\nOnly use this if your game API only supports LDtk 0.8.x or less.") );

				case PrependIndexToLevelFileNames:
					jLabel.text("Prefix level file names with their index in array");
					_setDesc( L.t._("If enabled, external level file names will be prefixed with an index reflecting their position in the internal array.\nThis is NOT recommended because, with versioning systems (such as GIT), inserting a new level means renaming files of all subsequent levels in the array.\nThis option used to be the default behavior but was changed in version 1.0.0.") );

				case MultiWorlds:
					jLabel.text("Multi-worlds support");
					_setDesc( L.t._("If enabled, levels will be stored in a 'worlds' array at the root of the project JSON instead of the root itself directly.\nThis option is still experimental and is not yet supported if Separate Levels option is enabled.") );
					jInput.prop("disabled", project.worlds.length>1 );

				case UseMultilinesType:
					jLabel.text('Use "Multilines" instead of "String" for fields in JSON');
					_setDesc( L.t._("If enabled, the JSON value \"__type\" for Field Instances and Field Definitions will be \"Multilines\" instead of \"String\" for all fields of Multilines type.") );

				case ExportOldTableOfContentData:
					jLabel.text('Export old entity table-of-content data');
					_setDesc( L.t._("If enabled, the 'toc' field in the project JSON will contain an 'instances' array in addition of the new 'instanceData' array (see JSON online doc for more info).") );

				case _:
			}

			var i = new form.input.BoolInput(
				jInput,
				()->project.hasFlag(flag),
				(v)->{
					editor.invalidateAllLevelsCache();
					editor.setProjectFlag(flag,v);
				}
			);
		}

		// Sample description
		var i = new form.input.StringInput(
			jForms.find("[name=tutorialDesc]"),
			()->project.tutorialDesc,
			(v)->{
				v = dn.Lib.trimEmptyLines(v);
				if( v=="" )
					v = null;
				project.tutorialDesc = v;
				editor.ge.emit(ProjectSettingsChanged);
			}
		);

		JsTools.parseComponents(jForms);
		checkBackup();
	}
}
