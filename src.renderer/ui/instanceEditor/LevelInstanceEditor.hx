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

			case WorldLevelMoved:
				updateForm();

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

	override function onFieldChange(keepCurrentSpecialTool=false) {
		super.onFieldChange(keepCurrentSpecialTool);

		editor.ge.emit( LevelSettingsChanged(inst) );
	}


	override function renderForm() {
		super.renderForm();

		if( inst==null || project.getLevel(inst.uid)==null ) {
			close();
			return;
		}

		var html = JsTools.getHtmlTemplate("levelInstanceEditor", { identifier:inst.identifier });
		jPanel.append(html);

		// Level name
		var i = Input.linkToHtmlInput( inst.identifier, jPanel.find("#identifier"));
		i.onChange = ()->onFieldChange();

		// Coords
		var i = Input.linkToHtmlInput( inst.worldX, jPanel.find("#worldX"));
		i.onChange = ()->onFieldChange();
		var i = Input.linkToHtmlInput( inst.worldY, jPanel.find("#worldY"));
		i.onChange = ()->onFieldChange();

		// Bg color
		var c = inst.getBgColor();
		var i = Input.linkToHtmlInput( c, jPanel.find("#bgColor"));
		i.isColorCode = true;
		i.onChange = ()->{
			inst.bgColor = c==project.defaultLevelBgColor ? null : c;
			onFieldChange();
		}
		var jDefault = i.jInput.siblings("a.reset");
		if( inst.bgColor==null )
			jDefault.hide();
		jDefault.click( (_)->{
			inst.bgColor = null;
			onFieldChange();
		});
		if( inst.bgColor!=null )
			i.jInput.siblings("span.usingDefault").hide();

		jPanel.find("button.delete").click( (_)->{
			if( project.levels.length<=1 ) {
				N.error( L.t._("You can't remove last level.") );
				return;
			}

			new ui.modal.dialog.Confirm(
				Lang.t._("Are you sure you want to delete this level?"),
				true,
				()->{
					var dh = new dn.DecisionHelper(project.levels);
					dh.removeValue(inst);
					dh.score( (l)->-inst.getBoundsDist(l) );

					new LastChance('Level ${inst.identifier} removed', project);
					project.removeLevel(inst);
					editor.ge.emit( LevelRemoved(inst) );
					editor.selectLevel( dh.getBest() );
				}
			);
		});

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