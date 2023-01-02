package ui.modal.dialog;

class IntGridValuePicker extends ui.modal.Dialog {
	var ld : data.def.LayerDef;
	var sourceLd : data.def.LayerDef;

	public function new(ld:data.def.LayerDef, current=-1, onConfirm:Int->Void, ?onCancel:Void->Void) {
		super();

		this.ld = ld;
		addClass("intGridValuePicker");
		var jList= new J('<ul/>');
		jContent.append(jList);
		sourceLd = ld.type==IntGrid ? ld : ld.autoSourceLd;
		if( sourceLd==null ) {
			N.error("Invalid source IntGrid layer");
			close();
			return;
		}
		for(id in sourceLd.getAllIntGridValues()) {
			var jValue = makeIntGridId(id.value, id.value==current);
			jValue.click(_->{
				onConfirm(id.value);
				close();
			});
			jList.append(jValue);
		}

		addCancel(onCancel);
	}


	function makeIntGridId(id:Int, active:Bool) {
		var jId = new J('<li/>');
		if( active )
			jId.addClass("active");

		if( sourceLd.getIntGridValueDisplayName(id)!=null )
			jId.append(sourceLd.getIntGridValueDisplayName(id));
		else
			jId.append('#$id');

		if( active )
			jId.append(" (current)");

		jId.css({ backgroundColor: sourceLd.getIntGridValueColor(id).toHex() });
		return jId;
	}
}