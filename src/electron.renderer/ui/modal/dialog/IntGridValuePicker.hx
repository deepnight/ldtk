package ui.modal.dialog;

class IntGridValuePicker extends ui.modal.Dialog {
	var ld : data.def.LayerDef;
	var sourceLd : data.def.LayerDef;

	public function new(?jNear:js.jquery.JQuery, ld:data.def.LayerDef, current=0, ?zeroValueLabel:String, onConfirm:Int->Void, ?onCancel:Void->Void) {
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

		if( zeroValueLabel!=null )
			jList.append( makeIntGridId(0, current==0, zeroValueLabel, onConfirm) );

		for(id in sourceLd.getAllIntGridValues())
			jList.append( makeIntGridId(id.value, id.value==current, onConfirm) );

		if( jNear!=null ) {
			jWrapper.css("minWidth", jNear.outerWidth()+"px");
			setAnchor( MA_JQuery(jNear) );
			jWrapper.offset({
				top: jWrapper.offset().top-jNear.outerHeight(),
				left: jWrapper.offset().left,
			});
		}
	}


	function makeIntGridId(value:Int, active:Bool, ?customLabel:String, onConfirm:Int->Void) {
		var jId = new J('<li/>');
		if( active )
			jId.addClass("active");
		jId.attr("value",Std.string(value));

		if( customLabel!=null )
			jId.append(customLabel);
		else if( value>0 && sourceLd.getIntGridValueDisplayName(value)!=null )
			jId.append(sourceLd.getIntGridValueDisplayName(value));
		else
			jId.append('#$value');

		if( active )
			jId.append(" (current)");

		if( value>0 )
			jId.css({ backgroundColor: sourceLd.getIntGridValueColor(value).toHex() });

		jId.click(_->{
			onConfirm(value);
			close();
		});

		return jId;
	}
}