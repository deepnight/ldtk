package ui;

class TagEditor {
	public var jEditor : js.jquery.JQuery;
	var onChange : Void->Void;
	var tags : data.Tags;

	public function new(tags:data.Tags, onChange) {
		this.tags = tags;
		this.onChange = onChange;

		jEditor = new J('<div class="tagEditor"/>');
		renderAll();
	}

	function renderAll() {
		jEditor.empty();

		for( k in tags.map.keys() )
			createTag(k);

		var jAdd = new J('<button class="add transparent"> <span class="icon add"/> </button>');
		jAdd.appendTo(jEditor);
		jAdd.click( _->{
			createInput();
			jEditor.append(jAdd);
		});
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
			if( v==k )
				createTag(jInput, v); // no change
			else if( v!=null ) {
				tags.unset(k);
				if( tags.has(v) )
					jInput.remove(); // duplicate
				else {
					tags.set(v);
					createTag(jInput, v); // changed
				}
				onChange();
			}
			else
				jInput.remove(); // invalid tag
		});
		jInput.blur( _->renderAll() );
		jInput.focus();
	}

}