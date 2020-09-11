// Source: https://github.com/SortableJS/Sortable

package sortablejs;

typedef SortableDragEvent = {
	var item: js.html.Element;
	var oldIndex: Int;
	var newIndex: Int;
}

typedef SortableOptions = {
	var ?onStart: (SortableDragEvent)->Void;
	var ?onEnd: (SortableDragEvent)->Void;
	var ?handle: String;
	var ?filter: String;

	var ?animation: Int; // ms

	var ?scroll: js.html.Element;
	var ?bubbleScroll: Bool;
	var ?scrollSpeed: Int; // px
	var ?scrollSensitivity: Int; // px

	var ?forceFallback: Bool;
	var ?fallbackTolerance: Int; // px
}

@:jsRequire("sortablejs")
extern class Sortable {
	public static function create(el:js.html.Element, ?options:SortableOptions) : Void;
}