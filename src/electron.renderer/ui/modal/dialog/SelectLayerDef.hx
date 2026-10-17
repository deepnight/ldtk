package ui.modal.dialog;

class SelectLayerDef extends ui.modal.Dialog {
	private var jDefSelect : js.jquery.JQuery;
	private var jConfirm : js.jquery.JQuery;

	public function new(?target:js.jquery.JQuery, onConfirm:data.def.LayerDef->Void) {
		super(target, "selectLayerDef");

		// LayerDef select
		jDefSelect = new J("<select name=layerDef/>");
		jContent.append(jDefSelect);

		var opt = new J("<option/>");
		opt.appendTo(jDefSelect);
		opt.attr("value", -1);
		opt.text("-- Select a layer definition --");

		for( ld in project.defs.layers ) {
			var opt = new J("<option/>");
			opt.appendTo(jDefSelect);
			opt.attr("value", ld.uid);
			opt.text(ld.identifier);
		}

		jDefSelect.change( (_)->{
			updateValidity();
		});


		// Buttons
		jConfirm = addConfirm(()->{
			var layerDef = project.defs.getLayerDef(null, jDefSelect.val());

			close();

			if (layerDef!=null)
				onConfirm(layerDef);
		});
		jConfirm.prop("disabled",true);

		addCancel();
	}

	private function updateValidity() {
		jConfirm.prop("disabled", !isValid());
	}

	private function isValid() {
		var isValid = true;

		if(jDefSelect.val() == -1)
			isValid = false;

		return isValid;
	}
}
