package ui.win;

class ProjectSettings extends ui.Window {
	public function new() {
		super();

		loadTemplate( hxd.Res.tpl.projectSettings, "projectSettings" );
	}

	override function onGlobalEvent(e:GlobalEvent) {
		super.onGlobalEvent(e);
		switch e {
			case LayerDefChanged:
			case LayerDefSorted:
			case LayerContentChanged:

			case EntityDefChanged:
			case EntityDefSorted:
			case EntityFieldChanged:
		}
	}
}
