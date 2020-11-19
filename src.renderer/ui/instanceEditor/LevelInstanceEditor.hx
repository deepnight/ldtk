package ui.instanceEditor;

class LevelInstanceEditor extends ui.InstanceEditor<data.Level> {

	private function new(l:data.Level) {
		super(l);
	}

	override function onGlobalEvent(ge:GlobalEvent) {
		super.onGlobalEvent(ge);
		switch ge {
			case ProjectSettingsChanged:
				if( inst==null )
					destroy();
				else
					updateForm();

			case LevelSelected(l):
				if( l!=inst )
					close();
				else
					updateForm();

			case LevelRemoved(l):
				if( l==this.inst )
					close();

			case ViewportChanged :
				renderLink();

			case _:
		}
	}

	override function renderLink() {
		super.renderLink();
		// drawLink( inst.def.color, inst.x, inst.y );
	}

	public static function openFor(l:data.Level) : LevelInstanceEditor {
		if( InstanceEditor.existsFor(l) )
			return cast InstanceEditor.CURRENT;
		else
			return new LevelInstanceEditor(l);
	}

	// override function onFieldChange(keepCurrentSpecialTool=false) {
	// 	super.onFieldChange(keepCurrentSpecialTool);

	// 	var editor = Editor.ME;
	// 	editor.curLevelHistory.saveLayerState( editor.curLayerInstance );
	// 	editor.curLevelHistory.setLastStateBounds( inst.left, inst.top, inst.def.width, inst.def.height );
	// 	editor.ge.emit( EntityInstanceFieldChanged(inst) );
	// }


	// override function getInstanceCx():Int {
	// 	return inst.getCx( Editor.ME.curLayerDef );
	// }

	// override function getInstanceCy():Int {
	// 	return inst.getCy( Editor.ME.curLayerDef );
	// }

	// override function getInstanceColor():UInt {
	// 	return inst.def.color;
	// }


	override function renderForm() {
		super.renderForm();

		if( inst==null || project.getLevel(inst.uid)==null ) {
			close();
			return;
		}

		// Form header
		var jHeader = new J('<header/>');
		jHeader.appendTo(jPanel);
		jHeader.append('<div>${inst.identifier}</div>');

		// var i = Input

		// // Custom fields
		// if( inst.def.fieldDefs.length==0 )
		// 	jPanel.append('<div class="empty">This entity has no custom field.</div>');
		// else {
		// 	// Field defs form
		// 	var jForm = renderFieldDefsForm(inst.def.fieldDefs, (fd)->inst.getFieldInstance(fd));
		// 	jForm.appendTo(jPanel);
		// }
	}
}