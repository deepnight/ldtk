package ui;

class TagEditor {
	public var jEditor : js.jquery.JQuery;
	var onChange : Void->Void;
	var tags : data.Tags;
	var allValuesGetter : Void->Array<String>;

	public function new(tags:data.Tags, onChange, allValuesGetter:Void->Array<String>) {
		this.tags = tags;
		this.onChange = onChange;
		this.allValuesGetter = allValuesGetter;

		jEditor = new J('<div class="tagEditor"/>');
		renderAll();
	}

	function renderAll() {
		jEditor.empty();

		for( k in tags.iterator() )
			createTag(k);

		var jButtons = new J('<div class="actions"/>');

		jButtons.appendTo(jEditor);
		var jAdd = new J('<button class="add dark"> <span class="icon add"/> </button>');
		jAdd.appendTo(jButtons);
		jAdd.click( _->{
			createInput();
			jEditor.append(jButtons);
		});

		// Recall button
		if( allValuesGetter().length>0 ) {
			var jRecall = new J('<button class="recall dark"> <span class="icon expandMore"/> </button>');
			jRecall.appendTo(jButtons);
			jRecall.click( ev->{
				var ctx = new ui.modal.ContextMenu(ev);
				for(v in allValuesGetter())
					ctx.add({
						label: L.untranslated(v),
						cb: ()->{
							tags.set(v);
							onChange();
						}
					});
				jEditor.append(jButtons);
			});
		}
	}

	function createTag(?jTarget:js.jquery.JQuery, k:String) {
		var jTag = new J('<div class="tag"> <div class="label">$k</div> </div>');
		if( jTarget!=null )
			jTarget.replaceWith(jTag);
		else
			jEditor.append(jTag);

		jTag.find(".label").click( _->{
			createInput(jTag, k);
		});

		var jDelete = new J('<button class="delete transparent"> <span class="icon delete"/> </button>');
		jDelete.appendTo(jTag);
		jDelete.click( _->{
			tags.unset(k);
			jTag.remove();
			onChange();
		});
	}


	function createInput(?jTarget:js.jquery.JQuery, k="") {
		var jInput = new J('<input type="text"/>');
		if( jTarget!=null ) {
			jInput.css({ width:jTarget.outerWidth()+"px" });
			jTarget.replaceWith(jInput);
		}
		else
			jEditor.append(jInput);

		var i = new form.input.StringInput(jInput, ()->k, v->{
			v = tags.cleanUpTag(v);
			if( v!=null && v!=k ) {
				tags.unset(k);
				if( !tags.has(v) )
					tags.set(v);
				jInput.blur();
				onChange();
			}
			else
				jInput.blur();
		});
		// jInput.focus( _->{
		// 	new ui.TypeSuggestion(jInput, allValuesGetter());
		// });
		jInput.blur( _->renderAll() );
		jInput.focus();
	}

}