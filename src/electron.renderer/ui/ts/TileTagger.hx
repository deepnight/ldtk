package ui.ts;

class TileTagger extends ui.Tileset {
	var ed : data.def.EnumDef;
	var jTools : js.jquery.JQuery;
	var jValues : js.jquery.JQuery;

	public function new(target, td) {
		super(target, td, None);
		this.ed = td.getTagsEnumDef();

		jTools = new J('<div class="tools"/>');
		jTools.appendTo(jWrapper);

		jValues = new J('<ul class="values niceList"/>');
		jValues.appendTo(jTools);
	}
}