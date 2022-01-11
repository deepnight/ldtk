package ui;

import data.inst.EntityInstance;

class EntityInstanceEditor extends dn.Process {
	public static var CURRENT : Null<EntityInstanceEditor> = null;
	static var PANEL_WIDTH : Float = -1;

	var editor(get,never) : Editor; inline function get_editor() return Editor.ME;
	var project(get,never) : data.Project; inline function get_project() return Editor.ME.project;

	var jWindow : js.jquery.JQuery;
	var ei : EntityInstance;
	var link : h2d.Graphics;
	var minPanelWidth : Int;


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
		minPanelWidth = Std.int( jWindow.innerWidth() );
		if( PANEL_WIDTH<=0 )
			PANEL_WIDTH = minPanelWidth;

		updateForm();
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
					updateForm();

			case EnumDefRemoved, EnumDefChanged, EnumDefSorted, EnumDefValueRemoved:
				updateForm();

			case EntityInstanceRemoved(ei):
				if( ei==this.ei )
					closeExisting();

			case EntityInstanceChanged(ei):
				if( ei==this.ei )
					updateForm();

			case EntityFieldInstanceChanged(ei,fi):
				if( ei==this.ei )
					updateForm();

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
		jWindow.find(".entityInstanceWrapper").scrollTop( scrollMem );
	}

	function onEntityFieldChanged() {
		editor.curLevelHistory.saveLayerState( editor.curLayerInstance );
		editor.curLevelHistory.setLastStateBounds( ei.left, ei.top, ei.def.width, ei.def.height );
}

	var scrollMem : Float = 0;
	final function updateForm() {
		jWindow.empty();
		jWindow.css("width", Math.ceil(PANEL_WIDTH) + "px");

		if( ei==null || ei.def==null ) {
			destroy();
			return;
		}


		var resizer = new J('<div class="resizeBar"></div>');
		resizer.appendTo(jWindow);
		resizer.mousedown(function( ev ) {
			js.Browser.document.addEventListener("mousemove", resizeDrag);
			js.Browser.document.addEventListener("mouseup", resizeDrag);
		});

		var wrapper = new J('<div class="entityInstanceWrapper"></div>');
		wrapper.appendTo(jWindow);

		// Form header
		var jHeader = new J('<header/>');
		jHeader.appendTo(wrapper);
		jHeader.append('<div>${ei.def.identifier}</div>');
		var jEdit = new J('<a class="edit">Edit</a>');
		jEdit.click( function(ev) {
			ev.preventDefault();
			new ui.modal.panel.EditEntityDefs(ei.def);
		});
		jHeader.append(jEdit);

		// Extra bits of info
		var jExtraInfos = new J('<dl class="form extraInfos"/>');
		jExtraInfos.appendTo(wrapper);

		// IID
		jExtraInfos.append('<dt>IID</dt>');
		var jIid = new J('<dd class="iid"/>');
		jIid.append('<input type="text" readonly="readonly" class="iid" value="${ei.iid}"/>');
		jIid.append('<button class="copy gray small" title="Copy IID to clipboard"> <span class="icon copy"/> </button>');
		jIid.find(".copy").click( _->{
			App.ME.clipboard.copyStr(ei.iid);
			N.msg("Copied to clipboard.");
		});
		jExtraInfos.append(jIid);

		// Pos
		jExtraInfos.append('<dt>Coords</dt>');
		var jCoords = new J('<dd/>');
		jCoords.append('<input type="text" name="x"/> <span>,</span> <input type="text" name="y"/> <span> ; </span>');
		jCoords.append('<input type="text" name="w"/> <span>x</span> <input type="text" name="h"/>');
		var i = Input.linkToHtmlInput(ei.x, jCoords.find("[name=x]"));
		i.setBounds(0, editor.curLevel.pxWid);
		i.linkEvent( EntityInstanceChanged(ei) );
		i.onChange = ()->onEntityFieldChanged();
		var i = Input.linkToHtmlInput(ei.y, jCoords.find("[name=y]"));
		i.setBounds(0, editor.curLevel.pxHei);
		i.linkEvent( EntityInstanceChanged(ei) );
		i.onChange = ()->onEntityFieldChanged();

		// Width
		var i = new form.input.IntInput(
			jCoords.find("[name=w]"),
			()->ei.width,
			(v)->ei.customWidth = v
		);
		i.setEnabled( ei.def.isResizable() );
		i.setBounds(ei.def.width, null);
		i.linkEvent( EntityInstanceChanged(ei) );
		i.onChange = ()->onEntityFieldChanged();

		// Height
		var i = new form.input.IntInput(
			jCoords.find("[name=h]"),
			()->ei.height,
			(v)->ei.customHeight = v
		);
		i.setEnabled( ei.def.isResizable() );
		i.setBounds(ei.def.height, null);
		i.linkEvent( EntityInstanceChanged(ei) );
		i.onChange = ()->onEntityFieldChanged();
		jExtraInfos.append(jCoords);

		// Custom fields
		var form = new ui.FieldInstancesForm();
		wrapper.append(form.jWrapper);
		form.use( Entity(ei), ei.def.fieldDefs, (fd)->ei.getFieldInstance(fd) );
		form.onChange = ()->onEntityFieldChanged();


		JsTools.parseComponents(jWindow);
		renderLink();

		// Re-position
		onResize();
		applyScrollMemory();
		wrapper.scroll( (_)->{
			scrollMem = wrapper.scrollTop();
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