package sortablejs;

typedef SortableOptions = {
	var ?onEnd: { oldIndex:Int, newIndex:Int }->Void;
	var ?handle: String;

	var ?scroll: js.html.Element;
	var ?bubbleScroll: Bool;
	var ?scrollSpeed: Int; // px
	var ?scrollSensitivity: Int; // px
}

@:jsRequire("sortablejs")
extern class Sortable {
	public static function create(el:js.html.Element, ?options:SortableOptions) : Void;
}