package ui.modal.dialog;

class InputDialog<T> extends ui.modal.Dialog {
	var confirm : Void->Void;

	public function new(desc:dn.data.GetText.LocaleString, ?curValue:T, ?suffix="", ?checkError:String->Null<String>, parser:String->T, onConfirm:T->Void) {
		super("inputDialog");

		loadTemplate("inputDialog");
		var jDesc = jContent.find(".desc");
		var p = '<p>' + StringTools.replace(desc,"\n","</p><p>") + '</p>';
		jDesc.append(p);

		var jError = jContent.find(".error");
		var jInput = jContent.find("input[type=text]");
		if( curValue!=null )
			jInput.val( Std.string(curValue) );
		jInput.focus().select();
		jInput.blur( _->{
			if( checkError!=null ) {
				var err = checkError( jInput.val() );
				jError.text(err);
			}
			jInput.val( Std.string( parser(jInput.val()) ) );
		});

		if( suffix!=null )
			jContent.find(".suffix").text(suffix);

		confirm = ()->{
			onConfirm( parser(jInput.val()) );
			close();
		}

		addConfirm( confirm );
		addCancel();
	}

	override function onKeyPress(keyCode:Int) {
		super.onKeyPress(keyCode);
		if( keyCode==K.ENTER )
			confirm();
	}
}