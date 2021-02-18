package data;

class Tags {
	var map : Map<String,Bool>;

	public function new() {
		map = new Map();
	}

	@:keep
	public function toString() {
		return 'Tags(${count()}):[${toArray().join(",")}]';
	}

	public inline function count() {
		var n = 0;
		for(v in map)
			n++;
		return n;
	}

	inline function cleanUpTag(k:String) : Null<String> {
		k = Project.cleanupIdentifier(k,false);
		return k==null || k=="_" || k=="" ? null : k;
	}

	public inline function set(k:String, v=true) : String {
		k = cleanUpTag(k);
		if( k!=null )
			if( v )
				map.set(k,v);
			else
				map.remove(k);
		return k;
	}

	public inline function unset(k:String) : String {
		return set(k,false);
	}

	public inline function toggle(k) {
		if( has(k) )
			unset(k);
		else
			set(k);
	}

	public inline function has(k) {
		k = cleanUpTag(k);
		return k!=null && map.exists(k);
	}

	public inline function clear() {
		map = new Map();
	}

	public function toArray() : Array<String> {
		var all = [];
		for(k in map.keys())
			all.push(k);
		return all;
	}

	public function fromArray(arr:Array<String>) {
		map = new Map();
		for( k in arr )
			set(k,true);
	}

	public function toJson() : Array<String> {
		return toArray();
	}

	public static function fromJson(json:Dynamic) : Tags {
		var o = new Tags();
		o.fromArray( JsonTools.readArray(json,[]) );
		return o;
	}



	/* ******************************************************
	JQuery editor
	********************************************************/

	public function createEditor(onChange:Void->Void) : js.jquery.JQuery {
		var jEditor = new J('<div class="tagEditor"/>');
		renderEditor(jEditor, onChange);
		return jEditor;
	}

	function createInput(jEditor:js.jquery.JQuery, ?jTarget:js.jquery.JQuery, k="", onChange:Void->Void) {
		var jInput = new J('<input type="text"/>');
		if( jTarget!=null ) {
			jInput.css({ width:jTarget.outerWidth()+"px" });
			jTarget.replaceWith(jInput);
		}
		else
			jEditor.append(jInput);

		var i = new form.input.StringInput(jInput, ()->k, v->{
			v = cleanUpTag(v);
			if( v==k )
				createTag(jEditor, jInput, v, onChange); // no change
			else if( v!=null ) {
				unset(k);
				if( has(v) )
					jInput.remove(); // duplicate
				else {
					set(v);
					createTag(jEditor, jInput, v, onChange); // changed
				}
				onChange();
			}
			else
				jInput.remove(); // invalid tag
		});
		jInput.blur( _->renderEditor(jEditor, onChange) );
		jInput.focus();
	}

	function createTag(jEditor:js.jquery.JQuery, ?jTarget:js.jquery.JQuery, k:String, onChange:Void->Void) {
		var jTag = new J('<div class="tag"> <div class="label">$k</div> </div>');
		if( jTarget!=null )
			jTarget.replaceWith(jTag);
		else
			jEditor.append(jTag);

		jTag.find(".label").click( _->{
			createInput(jEditor, jTag, k, onChange);
		});

		var jDelete = new J('<button class="delete transparent"> <span class="icon delete"/> </button>');
		jDelete.appendTo(jTag);
		jDelete.click( _->{
			unset(k);
			jTag.remove();
		});
	}

	function renderEditor(jEditor:js.jquery.JQuery, onChange:Void->Void) {
		jEditor.empty();

		for( k in map.keys() )
			createTag(jEditor, k, onChange);

		var jAdd = new J('<button class="add transparent"> <span class="icon add"/> </button>');
		jAdd.appendTo(jEditor);
		jAdd.click( _->{
			createInput(jEditor, onChange);
			jEditor.append(jAdd);
		});
	}

	public function tidy() {}
}