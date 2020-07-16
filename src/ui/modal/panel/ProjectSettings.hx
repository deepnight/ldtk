package ui.modal.panel;

class ProjectSettings extends ui.modal.Panel {
	var curEnum : Null<led.def.EnumDef>;

	public function new() {
		super();

		loadTemplate( "projectSettings", "projectSettings" );
		linkToButton("button.editProject");

		jContent.find("button.new").click( function(ev) client.onNew(ev.getThis()) );
		jContent.find("button.load").click( function(_) client.onLoad() );
		jContent.find("button.saveAs").click( function(_) client.onSaveAs() );

		// Add enum
		jContent.find("button.createEnum").click( function(_) {
			var ed = project.defs.createEnumDef();
			client.ge.emit(EnumDefAdded);
			selectEnum(ed);
			jContent.find("ul.enumForm input:first").focus();
		});

		// Delete enum
		jContent.find("button.deleteEnum").click( function(ev) {
			if( curEnum==null ) {
				N.error(L.t._("No enum selected."));
				return;
			}

			new ui.modal.dialog.Confirm(ev.getThis(), function() {
				new ui.LastChance( L.t._("Enum deleted"), project.toJson() );
				project.defs.removeEnumDef(curEnum);
				client.ge.emit(EnumDefRemoved);
				selectEnum( project.defs.enums[0] );
			});
		});

		if( project.defs.enums.length>0 )
			selectEnum( project.defs.enums[0] );

		updateProjectForm();
		updateEnumList();
		updateEnumForm();
	}

	override function onGlobalEvent(ge:GlobalEvent) {
		super.onGlobalEvent(ge);

		switch(ge) {
			case ProjectSelected:
				selectEnum( project.defs.enums[0] );

			case _:
		}

		updateProjectForm();
		updateEnumList();
		updateEnumForm();
	}

	function updateProjectForm() {
		var jForm = jContent.find("ul.form:first");

		var i = Input.linkToHtmlInput( project.name, jForm.find("[name=pName]") );
		i.linkEvent(ProjectSettingsChanged);

		var i = Input.linkToHtmlInput( project.defaultGridSize, jForm.find("[name=defaultGridSize]") );
		i.setBounds(1,Const.MAX_GRID_SIZE);
		i.linkEvent(ProjectSettingsChanged);

		var i = Input.linkToHtmlInput( project.bgColor, jForm.find("[name=color]"));
		i.isColorCode = true;
		i.linkEvent(ProjectSettingsChanged);

		var pivot = jForm.find(".pivot");
		pivot.empty();
		pivot.append( JsTools.createPivotEditor(
			project.defaultPivotX, project.defaultPivotY,
			0x0,
			function(x,y) {
				project.defaultPivotX = x;
				project.defaultPivotY = y;
				client.ge.emit(ProjectSettingsChanged);
			}
		));
	}

	function selectEnum(ed:led.def.EnumDef) {
		curEnum = ed;
		updateEnumList();
		updateEnumForm();
	}

	function updateEnumList() {
		var jList = jContent.find(".enumList ul");
		jList.empty();

		for(ed in project.defs.enums) {
			var e = new J("<li/>");
			e.appendTo(jList);
			if( ed==curEnum )
				e.addClass("active");
			e.append('<span class="name">'+ed.name+'</span>');
			e.click( function(_) {
				selectEnum(ed);
			});
		}

		// Make list sortable
		JsTools.makeSortable(".window .enumList ul", function(from, to) {
			N.notImplemented();
			// var moved = project.defs.sortLayerDef(from,to);
			// select(moved);
			// client.ge.emit(LayerDefSorted);
		});

	}

	function updateEnumForm() {
		var jForm = jContent.find("ul.enumForm");
		jForm.off();

		if( curEnum==null ) {
			jForm.hide();
			return;
		}
		jForm.show();

		var i = Input.linkToHtmlInput( curEnum.name, jForm.find("[name=eName]") );
		i.linkEvent(EnumDefChanged);

		var ta = @:privateAccess new form.Input( jForm.find("textarea"), function() {
			return curEnum.values.join("\n") + ( curEnum.values.length>0 ? "\n" : "" );
		}, function(str:String) {
			curEnum.values = [];
			for(v in str.split("\n"))
				curEnum.addValue(v);
		});
		ta.linkEvent(EnumDefChanged);
	}
}
