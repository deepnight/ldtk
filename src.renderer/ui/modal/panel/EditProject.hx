package ui.modal.panel;

class EditProject extends ui.modal.Panel {

	public function new() {
		super();

		loadTemplate("editProject", "editProject", {
			app: Const.APP_NAME,
			ext: Const.FILE_EXTENSION,
		});
		linkToButton("button.editProject");

		jContent.find("button.save").click( function(ev) {
			editor.onSave();
		});

		jContent.find("button.saveAs").click( function(ev) {
			editor.onSave(true);
		});

		jContent.find("button.close").click( function(ev) {
			editor.onClose();
		});

		updateProjectForm();
	}

	override function onGlobalEvent(ge:GlobalEvent) {
		super.onGlobalEvent(ge);
		updateProjectForm();
	}

	function updateProjectForm() {
		var jForm = jContent.find("ul.form:first");

		var ext = dn.FilePath.extractExtension( editor.projectFilePath );
		var usesAppDefault = ext==Const.FILE_EXTENSION;
		var i = Input.linkToHtmlInput( usesAppDefault, jForm.find("[name=useAppExtension]") );
		i.onValueChange = (v)->{
			var old = editor.projectFilePath;
			var fp = dn.FilePath.fromFile( editor.projectFilePath );
			fp.extension = v ? Const.FILE_EXTENSION : "json";
			if( JsTools.fileExists(old) && JsTools.renameFile(old, fp.full) ) {
				App.ME.renameRecentProject(old, fp.full);
				editor.projectFilePath = fp.full;
				N.success(L.t._("Changed file extension to ::ext::", { ext:fp.extWithDot }));
			}
			else {
				N.error(L.t._("Couldn't rename project file!"));
			}
		}

		var i = Input.linkToHtmlInput( project.minifyJson, jForm.find("[name=minify]") );
		i.linkEvent(ProjectSettingsChanged);

		var i = Input.linkToHtmlInput( project.exportTiled, jForm.find("[name=tiled]") );
		i.linkEvent(ProjectSettingsChanged);
		i.onValueChange = function(v) {
			if( v )
				new ui.modal.dialog.Message(Lang.t._("Disclaimer: Tiled export is only meant to load your LDtk project in a game framework that only supports Tiled files. It is recommended to write your own LDtk JSON parser, as some LDtk features may not be supported.\nIt's not so complicated, I promise :)"), "project");
		}
		var fp = dn.FilePath.fromFile( editor.projectFilePath );
		fp.appendDirectory(fp.fileName+"_tiled");
		fp.fileWithExt = null;
		if( !JsTools.fileExists(fp.full) ) {
			fp.parseFilePath( editor.projectFilePath );
			fp.fileWithExt = null;
		}
		var jLocate = jForm.find("[name=tiled]").siblings(".locate").empty();
		if( project.exportTiled )
			jLocate.append( JsTools.makeExploreLink(fp.full, false) );

		var i = Input.linkToHtmlInput( project.defaultGridSize, jForm.find("[name=defaultGridSize]") );
		i.setBounds(1,Const.MAX_GRID_SIZE);
		i.linkEvent(ProjectSettingsChanged);

		var i = Input.linkToHtmlInput( project.bgColor, jForm.find("[name=bgColor]"));
		i.isColorCode = true;
		i.linkEvent(ProjectSettingsChanged);

		var i = Input.linkToHtmlInput( project.defaultLevelbgColor, jForm.find("[name=defaultLevelbgColor]"));
		i.isColorCode = true;
		i.linkEvent(ProjectSettingsChanged);

		var e = new form.input.EnumSelect(
			jForm.find("[name=worldLayout]"),
			data.DataTypes.WorldLayout,
			()->project.worldLayout,
			(l)->project.worldLayout = l,
			(l)->switch l {
				case Free: L.t._("FREE - freely positioned in space");
				case LinearHorizontal: L.t._("LINEAR (horizontal) - one level after the other");
			}
		);
		if( project.levels.length>2 )
			e.confirmMessage = L.t._("Changing this might affect ALL the levels layout, so please make sure you know what you're doing :)");
		e.onValueChange = (l)->{
			project.reorganizeWorld();
		}
		e.linkEvent( ProjectSettingsChanged );


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
