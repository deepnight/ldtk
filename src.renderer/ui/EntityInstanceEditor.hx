package ui;

import data.inst.EntityInstance;

class EntityInstanceEditor extends dn.Process {
	public static var CURRENT : Null<EntityInstanceEditor> = null;
	public static var size : Float = 220;

	var editor(get,never) : Editor; inline function get_editor() return Editor.ME;
	var project(get,never) : data.Project; inline function get_project() return Editor.ME.project;

	var jWindow : js.jquery.JQuery;
	var ei : EntityInstance;
	var link : h2d.Graphics;

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
			left : (js.Browser.window.innerWidth - Math.floor(size)) + "px",
			top : Std.int(js.Browser.window.innerHeight*0.5 - jWindow.outerHeight()*0.5)+"px",
		});
	}

	function onGlobalEvent(ge:GlobalEvent) {
		switch ge {
			case ProjectSettingsChanged, EntityDefChanged, EntityFieldDefChanged(_), EntityFieldSorted:
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

			case LayerInstanceRestoredFromHistory(_), LevelRestoredFromHistory(_):
				closeExisting(); // TODO do softer refresh

			case LayerInstanceSelected:
				closeExisting();

			case ViewportChanged :
				renderLink();

			case _:
		}
	}

	function resizeDrag( ev : js.html.MouseEvent ) {
		if ( ev.type == "mouseup" ) {
			js.Browser.document.removeEventListener("mousemove", resizeDrag);
			js.Browser.document.removeEventListener("mouseup", resizeDrag);
		}
		size = dn.M.fclamp((js.Browser.window.innerWidth - ev.pageX), 220, 820);
		js.Browser.window.requestAnimationFrame(updateResize);
	}
	
	function updateResize( stamp : Float ) {
		jWindow.css("width", Math.ceil(size) + "px");
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
		var coords = Coords.fromWorldCoords(ei.x, ei.y);
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


	final function updateForm() {
		jWindow.empty();
		jWindow.css("width", Math.ceil(size) + "px");

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

		// Custom fields
		var form = new ui.FieldInstancesForm(Entity(ei), ei.def.fieldDefs, (fd)->ei.getFieldInstance(fd));
		wrapper.append(form.jWrapper);
		form.onChange = ()->{
			editor.curLevelHistory.saveLayerState( editor.curLayerInstance );
			editor.curLevelHistory.setLastStateBounds( ei.left, ei.top, ei.def.width, ei.def.height );
			editor.ge.emit( EntityInstanceFieldChanged(ei) );
			onResize();
		}

		JsTools.parseComponents(jWindow);
		renderLink();

		// Re-position
		onResize();
	}
}