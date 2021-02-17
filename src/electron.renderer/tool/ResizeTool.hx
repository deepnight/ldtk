package tool;

class ResizeTool extends Tool<Int> {
	var draggedHandle: Null<RectHandlePos>;
	var g : h2d.Graphics;
	var ge: GenericLevelElement;

	public function new(ge:GenericLevelElement) {
		super();
		this.ge = ge;
		createRootInLayers(editor.levelRender.root, Const.DP_UI);
		g = new h2d.Graphics(root);

		switch ge {
			case GridCell(li, cx, cy):

			case Entity(li, ei):
				g.beginFill(0xff00ff,0.5);
				var p = 4;
				g.drawRect(ei.x-p, ei.y-p, ei.def.width+p*2, ei.def.height+p*2);

			case PointField(li, ei, fi, arrayIdx):
		}
	}

	override function isRunning():Bool {
		return false;
	}

	override function startUsing(ev:hxd.Event, m:Coords) {
		super.startUsing(ev,m);
		curMode = null;
	}

	override function onMouseMove(ev:hxd.Event, m:Coords) {
		super.onMouseMove(ev, m);
	}

	override function postUpdate() {
		super.postUpdate();
		// root.x = editor.levelRender.root.x;
		// root.y = editor.levelRender.root.y;
		// root.setScale( editor.levelRender.root.scaleX );
	}

}