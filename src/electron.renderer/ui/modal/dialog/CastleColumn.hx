package ui.modal.dialog;

import cdb.Data;

class CastleColumn extends ui.modal.Dialog {
	var onConfirm : Null<Void->Void>;

	public function new(sheet:cdb.Sheet, ?onConfirm:Void->Void) {
		super();
		this.onConfirm = onConfirm;
		loadTemplate("castleColumn");

		var jConfirm = jContent.find(".confirm");
		var jCancel = jContent.find(".cancel");

		jCancel.click( _-> {
			close();
		});

		jConfirm.click( _-> {
			var name = jContent.find("input[name=name]").val();
			var type:ColumnType = switch( jContent.find("select[name=type]").val()) {
				case "id": TId;
				case "int": TInt;
				case "float": TFloat;
				case "string": TString;
				case "bool": TBool;
				case "enum":
					TImage;
					// var vals = StringTools.trim(v.values).split("\n");
					// vals = [for ( v in vals) for (e in v.split(",")) e];
					// vals.removeIf(function(e) {
					// 	return StringTools.trim(e) == "";
					// });
					// if( vals.length == 0 ) {
					// 	error("Missing value list");
					// 	return null;
					// }
					// TEnum([for( f in vals ) StringTools.trim(f)]);
				case "flags":
					TImage;
					// var vals = StringTools.trim(v.values).split("\n");
					// vals = [for ( v in vals) for (e in v.split(",")) e];
					// vals.removeIf(function(e) {
					// 	return StringTools.trim(e) == "";
					// });
					// if( vals.length == 0 ) {
					// 	error("Missing value list");
					// 	return null;
					// }
					// if( vals.length > 30 ) {
					// 	error("Too many possible values");
					// 	return null;
					// }
					// TFlags([for( f in vals ) StringTools.trim(f)]);
				case "ref":
					TImage;
					// var s = base.sheets[Std.parseInt(v.sheet)];
					// if( s == null ) {
					// 	error("Sheet not found");
					// 	return null;
					// }
					// TRef(s.name);
				case "image":
					TImage;
				case "list":
					TList;
				case "custom":
					TList;
					// var t = base.getCustomType(v.ctype);
					// if( t == null ) {
					// 	error("Type not found");
					// 	return null;
					// }
					// TCustom(t.name);
				case "color":
					TColor;
				case "layer":
					TColor;
					// var s = base.sheets[Std.parseInt(v.sheet)];
					// if( s == null ) {
					// 	error("Sheet not found");
					// 	return null;
					// }
					// TLayer(s.name);
				case "file":
					TFile;
				case "tilepos":
					TTilePos;
				case "tilelayer":
					TTileLayer;
				case "dynamic":
					TDynamic;
				case "properties":
					TProperties;
				case _:
					null;
			};
			var c:Column = {
				name: name,
				type: type,
				typeStr: null
			};
			if (jContent.find("input[name='required']").prop('checked')) c.opt = true;

			var result = sheet.addColumn(c);
			if (result != null) {
				Notification.error(result);
			}  else {
				Notification.success("Column created succesfully");
				close();
			}
		});
	}

	override function onKeyPress(keyCode:Int) {
		super.onKeyPress(keyCode);
		switch keyCode {
			case K.ENTER:
				//onConfirm(c);
				close();

			case _:
		}
	}

	
	override function onClickMask() {
		super.onClickMask();

		// if( onCancel!=null )
		// 	onCancel();
	}
}