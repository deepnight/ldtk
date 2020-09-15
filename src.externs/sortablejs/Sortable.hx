// Source: https://github.com/SortableJS/Sortable

package sortablejs;


typedef SortableDragEvent = {
	/** Dragged element **/
	var item: js.html.Element;

	/** Previous list **/
	var from: js.html.Element;

	/** Target list **/
	var to: js.html.Element;

	/** Element's old index within old parent **/
	var oldIndex: Int;

	/** Element's new index within old parent **/
	var newIndex: Int;

	/**  Element's old index within old parent, only counting draggable elements **/
	var oldDraggableIndex: Int;

	/**  Element's new index within old parent, only counting draggable elements **/
	var newDraggableIndex: Int;
}


typedef SortableOptions = {
	var ?onStart: (SortableDragEvent)->Void;
	var ?onEnd: (SortableDragEvent)->Void;

	/** Selector for handle **/
	var ?handle: String;

	/** Selector for excluded elements, separated with comma **/
	var ?filter: String;

	/** Sorting group name for nested lists **/
	var ?group: String;

	var ?animation: Int; // ms

	var ?scroll: js.html.Element;
	var ?bubbleScroll: Bool;
	var ?scrollSpeed: Int; // px
	var ?scrollSensitivity: Int; // px

	/**  Appends the cloned DOM Element into the Document's Body, recommended for nested lists **/
	var ?fallbackOnBody: Bool;
}


@:jsRequire("sortablejs")
extern class Sortable {
	public static function create(el:js.html.Element, ?options:SortableOptions) : Void;
}