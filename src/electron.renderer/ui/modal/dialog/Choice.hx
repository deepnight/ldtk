package ui.modal.dialog;

class Choice extends ui.modal.Dialog {
	public function new(str:LocaleString, choices:Array<{ label:String, cb:Void->Void, ?cond:Void->Bool, ?className:String }>, ?title:LocaleString, canCancel=true, ?onCancel:Void->Void) {
		super();

		jModalAndMask.addClass("choice");

		str = L.untranslated( '<p>'+str.split("\n").join("</p><p>")+'</p>' );
		jContent.html(str);

		if( title!=null )
			addTitle(title, true);

		for(c in choices)
			if( c.cond==null || c.cond() )
				addButton(L.untranslated(c.label), c.className, ()->{ // HACK untranslated
					close();
					c.cb();
				});

		canBeClosedManually = canCancel;
		if( canCancel )
			addCancel(onCancel);
	}
}