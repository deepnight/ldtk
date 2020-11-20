package ui;

class InstanceEditor<T> extends dn.Process {
	public static var CURRENT : Null<InstanceEditor<T>> = null;

	var editor(get,never) : Editor; inline function get_editor() return Editor.ME;
	var project(get,never) : data.Project; inline function get_project() return Editor.ME.project;

	var jPanel : js.jquery.JQuery;
	var inst : T;
	var link : h2d.Graphics;

	private function new(inst:T) {
		super(Editor.ME);

		closeAny();
		CURRENT = this;
		this.inst = inst;
		Editor.ME.ge.addGlobalListener(onGlobalEvent);

		link = new h2d.Graphics();
		Editor.ME.root.add(link, Const.DP_UI);

		jPanel = new J('<div class="instanceEditor"/>');
		App.ME.jPage.append(jPanel);

		updateForm();
	}

	override function onDispose() {
		super.onDispose();

		jPanel.remove();
		jPanel = null;

		link.remove();
		link = null;

		inst = null;

		if( CURRENT==this )
			CURRENT = null;
		Editor.ME.ge.removeListener(onGlobalEvent);
	}

	function onGlobalEvent(ge:GlobalEvent) {
		switch ge {
			case LayerInstanceSelected:
				close();

			case LayerInstanceRestoredFromHistory(_), LevelRestoredFromHistory(_):
				close(); // TODO do softer refresh?

			case ViewportChanged :
				renderLink();

			case _:
		}
	}


	function renderLink() {} // should be overriden

	final function drawLink(c:UInt, worldX:Int, worldY:Int) {
		jPanel.css("border-color", C.intToHex(c));
		var cam = Editor.ME.camera;
		var render = Editor.ME.levelRender;
		link.clear();
		link.lineStyle(4*cam.pixelRatio, c, 0.33);
		var coords = Coords.fromWorldCoords(worldX, worldY);
		link.moveTo(coords.canvasX, coords.canvasY);
		link.lineTo(
			cam.width - jPanel.outerWidth() * cam.pixelRatio,
			cam.height*0.5
		);
	}

	public static function existsFor(inst:Dynamic) {
		return isOpen() && CURRENT.inst==inst;
	}

	public static inline function isOpen() {
		return CURRENT!=null && !CURRENT.destroyed;
	}

	public static function closeAny() {
		if( isOpen() ) {
			CURRENT.close();
			CURRENT = null;
			return true;
		}
		else
			return false;
	}

	function close() {
		destroy();
	}


	function onFieldChange(keepCurrentSpecialTool=false) {
		if( !keepCurrentSpecialTool )
			Editor.ME.clearSpecialTool();

		updateForm();
	}


	function renderForm() {}
	final function updateForm() {
		jPanel.empty();
		jPanel.removeClass("picking");

		renderForm();
		if( destroyed )
			return;

		JsTools.parseComponents(jPanel);
		renderLink();

		// Re-position
		onResize();
	}
}