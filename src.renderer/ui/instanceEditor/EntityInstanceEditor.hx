package ui.instanceEditor;

class EntityInstanceEditor extends ui.InstanceEditor<data.inst.EntityInstance> {

	private function new(ei:data.inst.EntityInstance) {
		super(ei);
		jPanel.addClass("entity");
	}

	override function onGlobalEvent(ge:GlobalEvent) {
		super.onGlobalEvent(ge);
		switch ge {
			case ProjectSettingsChanged, EntityDefChanged, EntityFieldDefChanged(_), EntityFieldSorted:
				if( inst==null || inst.def==null )
					destroy();
				else
					updateForm();

			case EnumDefRemoved, EnumDefChanged, EnumDefSorted, EnumDefValueRemoved:
				updateForm();

			case EntityInstanceRemoved(ei):
				if( ei==this.inst )
					close();

			case EntityInstanceChanged(ei):
				if( ei==this.inst )
					updateForm();

			case LayerInstanceRestoredFromHistory(_), LevelRestoredFromHistory(_):
				close(); // TODO do softer refresh


			case ViewportChanged :
				updateForm();

			case _:
		}
	}

	override function renderLink() {
		super.renderLink();
		drawLink( inst.def.color, inst.x, inst.y );
	}

	public static function openFor(ei:data.inst.EntityInstance) : EntityInstanceEditor {
		if( InstanceEditor.existsFor(ei) )
			return cast InstanceEditor.CURRENT;
		else
			return new EntityInstanceEditor(ei);
	}

	override function onFieldChange(keepCurrentSpecialTool=false) {
		super.onFieldChange(keepCurrentSpecialTool);

		var editor = Editor.ME;
		editor.curLevelHistory.saveLayerState( editor.curLayerInstance );
		editor.curLevelHistory.setLastStateBounds( inst.left, inst.top, inst.def.width, inst.def.height );
		editor.ge.emit( EntityInstanceFieldChanged(inst) );
	}


	override function getInstanceCx():Int {
		return inst.getCx( Editor.ME.curLayerDef );
	}

	override function getInstanceCy():Int {
		return inst.getCy( Editor.ME.curLayerDef );
	}

	override function getInstanceColor():UInt {
		return inst.def.color;
	}


	override function renderForm() {
		super.renderForm();

		if( inst==null || inst.def==null ) {
			close();
			return;
		}

		// Form header
		var jHeader = new J('<header/>');
		jHeader.appendTo(jPanel);
		jHeader.append('<div>${inst.def.identifier}</div>');
		var jEdit = new J('<a class="edit">Edit</a>');
		jEdit.click( function(ev) {
			ev.preventDefault();
			new ui.modal.panel.EditEntityDefs(inst.def);
		});
		jHeader.append(jEdit);

		// Fields
		if( inst.def.fieldDefs.length==0 )
			jPanel.append('<div class="empty">This entity has no custom field.</div>');
		else {
			// Field defs form
			var jForm = renderFieldDefsForm(inst.def.fieldDefs, (fd)->inst.getFieldInstance(fd));
			jForm.appendTo(jPanel);
		}
	}
}