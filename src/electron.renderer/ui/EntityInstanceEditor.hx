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
		jWindow.html( JsTools.getHtmlTemplate("entityInstanceEditor", { id : inst.def.identifier }) );
		// jWindow.append('<div class="entityInstanceWrapper"/>');
		// jWrapper.append( new J('<div class="propsWrapper"></div>') );
		// jWrapper.append( new J('<div class="customFieldsWrapper"></div>') );

		// Panel resizing handle
		// var jResizeHandle = new J('<div class="resizeBar"></div>');
		// jResizeHandle.appendTo(jWindow);
		var jResizeHandle = jWindow.find(".resizeBar");
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

			case LayerInstancesRestoredFromHistory(_), LevelRestoredFromHistory(_):
				closeExisting(); // TODO do softer refresh

			case LayerInstanceSelected(li):
				closeExisting();

			case ViewportChanged(zoomChanged) :
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
		editor.curLevelTimeline.markEntityChange(ei);
		editor.curLevelTimeline.saveLayerState(ei._li);
	}


	function updateInstancePropsForm() {
		jPropsForm.find("*").off();
		ui.Tip.clear();

		// Form header
		jPropsForm.find("header .edit").click( function(ev) {
			ev.preventDefault();
			new ui.modal.panel.EditEntityDefs(ei.def);
		});

		var jExtraInfos = jPropsForm.find(".form.extraInfos");

		// IID
		var jIid = jPropsForm.find("dd.iid");
		jIid.find("input").val(ei.iid);
		jIid.find(".copy").click( _->{
			App.ME.clipboard.copyStr(ei.iid);
			N.copied();
		});

		// Coords block
		var jCoords = jPropsForm.find(".coords");
		var jUnit = jCoords.find(".unit");
		jUnit.text( UNIT_GRID ? "cells" : "px" );
		jUnit.click( _->{
			UNIT_GRID = !UNIT_GRID;
			updateInstancePropsForm();
		});

		var sliderSpeed = UNIT_GRID ? 0.05 : 1;
		// X
		var i = Input.linkToHtmlInput(ei.x, jCoords.find("[name=x]"));
		i.setBounds(0, editor.curLevel.pxWid);
		i.enableSlider(sliderSpeed, false);
		i.linkEvent( EntityInstanceChanged(ei) );
		i.onChange = ()->onEntityFieldChanged();
		if( UNIT_GRID )
			i.setUnit(ei._li.def.gridSize);

		// Y
		var i = Input.linkToHtmlInput(ei.y, jCoords.find("[name=y]"));
		i.setBounds(0, editor.curLevel.pxHei);
		i.enableSlider(sliderSpeed, false);
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
		i.enableSlider(sliderSpeed, false);
		i.setBounds(ei.def.minWidth==null ? 1 : ei.def.minWidth, ei.def.maxWidth);
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
		i.enableSlider(sliderSpeed, false);
		i.setBounds(ei.def.minHeight==null ? 1 : ei.def.minHeight, ei.def.maxHeight);
		i.linkEvent( EntityInstanceChanged(ei) );
		i.onChange = ()->onEntityFieldChanged();
		if( UNIT_GRID )
			i.setUnit(ei._li.def.gridSize);


		// References to this
		var refs = project.getEntityInstancesReferingTo(ei);
		var jRefs = jPropsForm.find(".entityRefs");
		jRefs.empty();
		if( refs.length==0 )
			jPropsForm.find(".refs").hide();
		else {
			jPropsForm.find(".refs").show();
			for(ei in refs) {
				var jRef = JsTools.createEntityRef(ei, true, jRefs);
				jRef.click( _->editor.followEntityRef(ei) );
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

		if( ei.def.doc!=null ) {
			jWrapper.find(".hasDoc").show();
			jWrapper.find(".doc").html( "<p>" + ei.def.doc.split("\n").join("</p><p>") + "</p>" );
		}
		else {
			jWrapper.find(".hasDoc").hide();
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