package ui;

class TagEditor {
	public var jEditor : js.jquery.JQuery;
	var onChange : Void->Void;
	var onRename : (oldT:String,newT:String)->Void;
	var otherTagsGetter : Void->Array<data.Tags>;
	var tags : data.Tags;
	var allValuesGetter : Void->Array<String>;
	var allowEditing : Bool;

	public function new(tags:data.Tags, onChange, allValuesGetter:Void->Array<String>, ?otherTagsGetter:Void->Array<data.Tags>, ?onRename:(oldT:String,newT:String)->Void, allowEditing=true) {
		this.tags = tags;
		this.otherTagsGetter = otherTagsGetter;
		this.onRename = onRename;
		this.onChange = onChange;
		this.allValuesGetter = allValuesGetter;
		this.allowEditing = allowEditing;

		jEditor = new J('<div class="tagEditor"/>');
		renderAll();
	}

	function renderAll() {
		jEditor.empty();

		for( k in tags.iterator() )
			createTag(k);

		var jButtons = new J('<div class="actions"/>');
		jButtons.appendTo(jEditor);

		if( tags.isEmpty() ) {
			// "No tag" label
			var jEmpty = new J('<span class="empty"></span>');
			jEmpty.text("(No tag)");
			if( allowEditing )
				jEmpty.click( ev->{
					createInput();
					jEmpty.remove();
					jEditor.append(jButtons); // move to end
				});
			else
				jEmpty.click( ev->onRecallTag(ev) );
			jEditor.prepend(jEmpty);
		}

		if( allowEditing ) {
			// Create new tag
			var jAdd = new J('<button class="add dark"> <span class="icon add"/> </button>');
			jAdd.appendTo(jButtons);
			jAdd.click( _->{
				createInput();
				jEditor.append(jButtons); // move to end
			});
		}

		// Recall button
		if( allValuesGetter().length>0 ) {
			var jRecall = new J('<button class="recall dark"> <span class="icon recall"/> </button>');
			jRecall.appendTo(jButtons);
			jRecall.click( ev->onRecallTag(ev) );
		}
	}

	function onRecallTag(ev:js.jquery.Event) {
		var ctx = new ui.modal.ContextMenu(ev);
		for(v in allValuesGetter())
			ctx.addAction({
				label: L.untranslated(v),
				cb: ()->{
					tags.set(v);
					onChange();
				}
			});

	}

	function createTag(?jTarget:js.jquery.JQuery, k:String) {
		var jTag = new J('<div class="tag"> <div class="label">$k</div> </div>');
		if( jTarget!=null )
			jTarget.replaceWith(jTag);
		else
			jEditor.append(jTag);

		if( allowEditing )
			jTag.find(".label").click( _->{
				createInput(jTag, k);
			});

		var jDelete = new J('<button class="delete transparent"> <span class="icon clear"/> </button>');
		jDelete.appendTo(jTag);
		jDelete.click( _->{
			tags.unset(k);
			jTag.remove();
			onChange();
		});
	}


	function createInput(?jTarget:js.jquery.JQuery, curValue="") {
		jEditor.find(".empty").remove();
		var jInput = new J('<input type="text"/>');
		if( jTarget!=null ) {
			jInput.css({ width:jTarget.outerWidth()+"px" });
			jTarget.replaceWith(jInput);
		}
		else
			jEditor.append(jInput);

		var i = new form.input.StringInput(jInput, ()->curValue, newValue->{
			newValue = data.Tags.cleanUpTag(newValue);
			if( newValue!=null && newValue!=curValue ) {
				function _do(renameEverywhere=true) {
					tags.unset(curValue);
					if( !tags.has(newValue) )
						tags.set(newValue);
					jInput.blur();
					if( renameEverywhere && otherTagsGetter!=null ) {
						for(tags in otherTagsGetter())
							tags.rename(curValue,newValue);
						if( onRename!=null )
							onRename(curValue,newValue);
					}
					onChange();
				}

				if( curValue!="" && otherTagsGetter!=null ) {
					var uses = 0;
					for(tags in otherTagsGetter())
						if( tags.has(curValue) ) {
							uses++;
							if( uses>=2 )
								break;
						}
					if( uses<=1 )
						_do();
					else
						new ui.modal.dialog.Choice(
							L.t._("This tag is used in other elements!\nDo you want to rename it in ALL other elements as well, or only here?"),
							[
								{ label:"Rename everywhere", cb: ()->_do(true) },
								{ label:"Rename only here", cb: ()->_do(false) },
							]
						);
				}
				else
					_do();

			}
			else
				jInput.blur();
		});
		jInput.blur( _->renderAll() );
		jInput.focus();
	}

}