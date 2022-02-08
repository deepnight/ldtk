package ui;

import data.inst.EntityInstance;

class EntityInstanceEditor extends dn.Process {
	public static var UNIT_GRID = false;
	public static var CURRENT : Null<EntityInstanceEditor> = null;
	static var PANEL_WIDTH : Float = -1;

	var editor(get,never) : Editor; inline function get_editor() return Editor.ME;
	var project(get,never) : data.Project; inline function get_project() return Editor.ME.project;

	var jWindow : js.jquery.JQuery;
	var ei : EntityInstance;
	var link : h2d.Graphics;
	var minPanelWidth : Int;
	var customFieldsForm : FieldInstancesForm;

	var jWrapper(get,never) : js.jquery.JQuery; inline function get_jWrapper() return jWindow.find(".entityInstanceWrapper");
	var jPropsForm(get,never) : js.jquery.JQuery; inline function get_jPropsForm() return jWindow.find(".propsWrapper");


	private function new(inst:data.inst.EntityInstance) {
		super(Editor.ME);

		closeExisting();
		CURRENT = this;
		ei = inst;
		Editor.ME.ge.addGlobalListener(onGlobalEvent);

		link = new h2d.Graphics();
		Editor.ME.root.add(link, Const.DP_UI);

		jWindow = new J('<div class="entityInstanceEditor"/>');
		App.ME.jPage.append(jWindow);
		jWindow.append('<div class="entityInstanceWrapper"/>');
		jWrapper.append( new J('<div class="propsWrapper"></div>') );
		jWrapper.append( new J('<div class="customFieldsWrapper"></div>') );

		// Panel resizing handle
		var jResizeHandle = new J('<div class="resizeBar"></div>');
		jResizeHandle.appendTo(jWindow);
		jResizeHandle.mousedown(function( ev ) {
			js.Browser.document.addEventListener("mousemove", resizeDrag);
			js.Browser.document.addEventListener("mouseup", resizeDrag);
		});
		minPanelWidth = Std.int( jWindow.innerWidth() );
		if( PANEL_WIDTH<=0 )
			PANEL_WIDTH = minPanelWidth;
		jWindow.css("width", Math.ceil(PANEL_WIDTH) + "px");

		// Create custom fields form
		customFieldsForm = new ui.FieldInstancesForm();
		customFieldsForm.onChange = ()->onEntityFieldChanged();
		jWrapper.find(".customFieldsWrapper").append( customFieldsForm.jWrapper );

		updateAllForms();
	}

	override function onDispose() {
		super.onDispose();

		js.Browser.document.removeEventListener("mousemove", resizeDrag);
		js.Browser.document.removeEventListener("mouseup", resizeDrag);
		jWindow.remove();
		jWindow = null;

		link.remove();
		link = null;

		ei = null;

		if( CURRENT==this )
			CURRENT = null;
		Editor.ME.ge.removeListener(onGlobalEvent);
	}


	override function onResize() {
		super.onResize();

		jWindow.css({
			left : (js.Browser.window.innerWidth - Math.floor(PANEL_WIDTH)) + "px",
			top : Std.int(js.Browser.window.innerHeight*0.5 - jWindow.outerHeight()*0.5)+"px",
		});
	}

	function onGlobalEvent(ge:GlobalEvent) {
		switch ge {
			case ProjectSettingsChanged, EntityDefChanged, FieldDefChanged(_), FieldDefSorted:
				if( ei==null || ei.def==null )
					destroy();
				else
					updateAllForms();

			case EnumDefRemoved, EnumDefChanged, EnumDefSorted, EnumDefValueRemoved:
				updateAllForms();

			case EntityInstanceRemoved(ei):
				if( ei==this.ei )
					closeExisting();

			case EntityInstanceChanged(ei):
				if( ei==this.ei )
					updateAllForms();

			case EntityFieldInstanceChanged(ei,fi):
				if( ei==this.ei )
					updateAllForms();

			case LayerInstanceRestoredFromHistory(_), LevelRestoredFromHistory(_):
				closeExisting(); // TODO do softer refresh

			case LayerInstanceSelected:
				closeExisting();

			case ViewportChanged :
				renderLink();

			case LevelSelected(level):
				closeExisting();

			case _:
		}
	}

	function resizeDrag( ev : js.html.MouseEvent ) {
		if ( ev.type == "mouseup" ) {
			js.Browser.document.removeEventListener("mousemove", resizeDrag);
			js.Browser.document.removeEventListener("mouseup", resizeDrag);
		}
		PANEL_WIDTH = dn.M.fclamp((js.Browser.window.innerWidth - ev.pageX), minPanelWidth, 820);
		js.Browser.window.requestAnimationFrame(updateResize);
	}

	function updateResize( stamp : Float ) {
		jWindow.css("width", Math.ceil(PANEL_WIDTH) + "px");
		renderLink();
		onResize();
	}

	function renderLink() {
		var c = ei.def.color;
		jWindow.css("border-color", C.intToHex(c));
		var cam = Editor.ME.camera;
		var render = Editor.ME.levelRender;
		link.clear();
		link.lineStyle(4*cam.pixelRatio, c, 0.33);
		var coords = Coords.fromLevelCoords(ei.centerX, ei.centerY);
		link.moveTo(coords.canvasX, coords.canvasY);
		link.lineTo(
			cam.width - jWindow.outerWidth() * cam.pixelRatio,
			cam.height*0.5
		);
	}

	public static function openFor(ei:data.inst.EntityInstance) : EntityInstanceEditor {
		if( existsFor(ei) )
			return CURRENT;
		else
			return new EntityInstanceEditor(ei);
	}

	public static function existsFor(inst:data.inst.EntityInstance) {
		return isOpen() && CURRENT.ei==inst;
	}

	public static inline function isOpen() {
		return CURRENT!=null && !CURRENT.destroyed;
	}

	public static function closeExisting() {
		if( isOpen() ) {
			CURRENT.destroy();
			CURRENT = null;
			return true;
		}
		else
			return false;
	}


	inline function applyScrollMemory() {
		jWrapper.scrollTop( scrollMem );
	}

	function onEntityFieldChanged() {
		editor.curLevelHistory.saveLayerState( editor.curLayerInstance );
		editor.curLevelHistory.setLastStateBounds( ei.left, ei.top, ei.def.width, ei.def.height );
	}


	function updateInstancePropsForm() {
		jPropsForm.empty();

		// Form header
		var jHeader = new J('<header/>');
		jHeader.appendTo(jPropsForm);
		jHeader.append('<div>${ei.def.identifier}</div>');
		var jEdit = new J('<a class="edit">Edit</a>');
		jEdit.click( function(ev) {
			ev.preventDefault();
			new ui.modal.panel.EditEntityDefs(ei.def);
		});
		jHeader.append(jEdit);

		// Collapser
		var jCollapser = new J('<div class="collapser" id="extraEntityInfos">Extra entity infos</div>');
		jCollapser.appendTo(jPropsForm);

		// Extra bits of info
		var jExtraInfos = new J('<dl class="form extraInfos"/>');
		jExtraInfos.appendTo(jPropsForm);

		// IID
		jExtraInfos.append('<dt>IID <info>The IID (stands for Instance IDentifier) is a unique string identifier associated with this Entity instance.</info></dt>');
		var jIid = new J('<dd class="iid"/>');
		jIid.append('<input type="text" readonly="readonly" class="iid" value="${ei.iid}"/>');
		jIid.append('<button class="copy gray small" title="Copy IID to clipboard"> <span class="icon copy"/> </button>');
		jIid.find(".copy").click( _->{
			App.ME.clipboard.copyStr(ei.iid);
			N.copied();
		});
		jExtraInfos.append(jIid);

		// Coords block
		jExtraInfos.append('<dt>Coords <info>Coordinates and dimensions in pixels or cells (you can switch the unit by click on it)</info></dt>');
		var jCoords = new J('<dd class="coords"/>');
		jCoords.append('<input type="text" name="x"/> <span>,</span> <input type="text" name="y"/> <span> ; </span>');
		jCoords.append('<input type="text" name="w"/> <span>x</span> <input type="text" name="h"/>');
		var jUnit = new J('<span class="unit" ttitle="Change unit"/>');
		jUnit.text( UNIT_GRID ? "cells" : "px" );
		jCoords.append(jUnit);
		jUnit.click( _->{
			UNIT_GRID = !UNIT_GRID;
			updateInstancePropsForm();
		});

		// X
		var i = Input.linkToHtmlInput(ei.x, jCoords.find("[name=x]"));
		i.setBounds(0, editor.curLevel.pxWid);
		i.linkEvent( EntityInstanceChanged(ei) );
		i.onChange = ()->onEntityFieldChanged();
		if( UNIT_GRID )
			i.setUnit(ei._li.def.gridSize);

		// Y
		var i = Input.linkToHtmlInput(ei.y, jCoords.find("[name=y]"));
		i.setBounds(0, editor.curLevel.pxHei);
		i.linkEvent( EntityInstanceChanged(ei) );
		i.onChange = ()->onEntityFieldChanged();
		if( UNIT_GRID )
			i.setUnit(ei._li.def.gridSize);

		// Width
		var i = new form.input.IntInput(
			jCoords.find("[name=w]"),
			()->ei.width,
			(v)->ei.customWidth = v
		);
		i.setEnabled( ei.def.resizableX );
		i.setBounds(ei.def.width, null);
		i.linkEvent( EntityInstanceChanged(ei) );
		i.onChange = ()->onEntityFieldChanged();
		if( UNIT_GRID )
			i.setUnit(ei._li.def.gridSize);

		// Height
		var i = new form.input.IntInput(
			jCoords.find("[name=h]"),
			()->ei.height,
			(v)->ei.customHeight = v
		);
		i.setEnabled( ei.def.resizableY );
		i.setBounds(ei.def.height, null);
		i.linkEvent( EntityInstanceChanged(ei) );
		i.onChange = ()->onEntityFieldChanged();
		jExtraInfos.append(jCoords);
		if( UNIT_GRID )
			i.setUnit(ei._li.def.gridSize);


		// References to this
		var refs = project.getEntityInstancesReferingTo(ei);
		if( refs.length>0 ) {
			jExtraInfos.append('<dt>References to this entity <info>This is a list of all other Entities having a Reference field pointing to this Entity.</info> </dt>');
			jExtraInfos.append('<dd><div class="entityRefs"/></dd>');
			var jList = jExtraInfos.find(".entityRefs");
			for(ei in refs) {
				var jRef = JsTools.createEntityRef(ei, true, jList);
				jRef.click(_->editor.followEntityRef(ei));
			}
		}
	}


	function updateCustomFields() {
		customFieldsForm.use( Entity(ei), ei.def.fieldDefs, (fd)->ei.getFieldInstance(fd,true) );
	}


	var scrollMem : Float = 0;
	final function updateAllForms() {
		if( ei==null || ei.def==null ) {
			destroy();
			return;
		}

		updateInstancePropsForm();
		updateCustomFields();
		JsTools.parseComponents(jWindow);
		renderLink();

		// Re-position
		onResize();
		applyScrollMemory();
		jWrapper.scroll( (_)->{
			scrollMem = jWrapper.scrollTop();
		});
	}

	override function update() {
		super.update();

		var isOccupied = editor.resizeTool!=null && editor.resizeTool.isRunning() || editor.selectionTool.isRunning();
		if( isOccupied && !jWindow.hasClass("faded") )
			jWindow.addClass("faded");
		if( !isOccupied && jWindow.hasClass("faded") )
			jWindow.removeClass("faded");
	}
}