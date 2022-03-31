package ui;

enum PatternBlock {
	Str(v:String);
	Var(v:String);
}

class FilePatternEditor {
	static var SEP = "%";
	static var BLOCKS = [
		"level_idx",
		"level_name",
		"world",
		"idx",
	];

	public var jEditor : js.jquery.JQuery;
	var jPattern : js.jquery.JQuery;
	var jExample : js.jquery.JQuery;
	var onChange : String->Void;
	var blocks : Array<PatternBlock>;

	var curInput : Null<js.jquery.JQuery>;
	var curEditIndex : Null<Int>;

	public function new(cur:String, onChange:String->Void) {
		this.onChange = onChange;
		jEditor = new J('<div class="filePatternEditor"/>');

		jPattern = new J('<div class="pattern"/>');
		jPattern.appendTo(jEditor);

		jExample = new J('<div class="example"/>');
		jExample.appendTo(jEditor);


		App.ME.jBody.off(".patternEditor");
		App.ME.jBody.on("keydown.patternEditor", onKey);
		N.debug("bound");
		ofString(cur);
	}

	function onKey(ev:js.jquery.Event) {
		if( jEditor.closest("body").length==0 ) {
			App.ME.jBody.off(".patternEditor");
			return;
		}

		if( curEditIndex==null )
			return;

		switch blocks[curEditIndex] {
			case Str(v):
				return;

			case Var(v):
				switch ev.key {
					case "ArrowRight":
						if( curEditIndex < blocks.length-1 )
							selectAt(curEditIndex+1, true);
						else {
							blocks.push( Str("") );
							renderAll();
							selectAt( blocks.length-1 );

						}

					case "ArrowLeft":
						if( curEditIndex >0 )
							selectAt(curEditIndex-1);
						else {
							blocks.insert(0, Str(""));
							renderAll();
							selectAt(0);
						}

					case "Delete", "Backspace":
						blocks.splice(curEditIndex, 1);
						renderAll();
						if( curEditIndex>=blocks.length && blocks.length>0 )
							selectAt(blocks.length-1);
						else if( curEditIndex<blocks.length )
							selectAt(curEditIndex, true);
				}
		}

		ev.stopPropagation();
		ev.preventDefault();
	}


	public function ofString(raw:String) {
		var remain = raw;
		blocks = [];
		while( remain.length>0 ) {
			if( remain.charAt(0)==SEP ) {
				var found = false;
				for(b in BLOCKS)
					if( remain.indexOf(SEP+b)==0 ) {
						blocks.push( Var(b) );
						remain = remain.substr(SEP.length + b.length);
						found = true;
						break;
					}
				if( !found ) {
					// Found a % with unknown var name
					var i = remain.indexOf(SEP,1);
					if( i<0 ) {
						blocks.push( Str(remain) );
						remain = "";
					}
					else {
						blocks.push( Str( remain.substr(0,i) ) );
						remain = remain.substr(i);
					}
				}
			}
			else {
				var i = remain.indexOf(SEP);
				if( i<0 ) {
					blocks.push( Str(remain) );
					remain = "";
				}
				else {
					blocks.push( Str( remain.substr(0,i) ) );
					remain = remain.substr(i);
				}
			}
		}
		renderAll();
	}


	function cleanupFileName(str:String) {
		var reg = ~/[ \/\\.%$:?"<>|*]/gim;
		return reg.replace(str, "_");
	}

	public function toString() {
		trace(blocks);
		var out = "";
		for(b in blocks)
			out += switch b {
				case Str(v): cleanupFileName(v);
				case Var(v): SEP+v;
			}
		return out;
	}

	function getBlock(idx:Int) : js.jquery.JQuery {
		return jPattern.children('.block[block-idx=$idx]');
	}

	function resizeInput() {
		if( curInput==null )
			return;
		var v = curInput.val();
		var jTmp = new J('<div class="block str tmp">$v</div>');
		jTmp.hide().insertAfter(curInput);
		curInput.css("width", jTmp.outerWidth());
		jTmp.remove();
	}


	function unselect() {
		curEditIndex = null;

		if( curInput!=null ) {
			curInput.remove();
			curInput = null;
		}

		jPattern.find(".selected").removeClass("selected");
	}

	function selectAt(idx:Int, cursorAtStart=false) {
		unselect();
		curEditIndex = idx;
		var b = blocks[curEditIndex];

		// Edit next Str block if this is a Var
		// switch b {
		// 	case null:
		// 	case Str(v):
		// 	case Var(v):
		// 		var next = blocks[curEditIndex+1];
		// 		if( next!=null && next.getIndex()==Str(null).getIndex() ) {
		// 			editAt(curEditIndex+1, true);
		// 			return;
		// 		}
		// }

		var jBlock = getBlock(curEditIndex);
		jBlock.addClass("selected");

		switch b {
			case Str(v):
				// Create input
				curInput = new J('<input type="text"/>');
				// if( curEditIndex>=0 ) {
					curInput.insertAfter(jBlock);
				// }
				// else
				// 	curInput.prependTo(jPattern);

				// Events
				curInput.on("input", _->{
					resizeInput();
				});
				curInput.keydown( (ev:js.jquery.Event)->{
					var i : js.html.InputElement = cast curInput.get(0);
					switch ev.key {
						case "Escape", "Enter":
							ev.preventDefault();
							ev.stopPropagation();
							curInput.blur();

						case "ArrowLeft", "Backspace":
							if( i.selectionStart==0 && curEditIndex>0 ) {
								ev.stopPropagation();
								applyEdit( curInput.val() );
								trace(curEditIndex);
								selectAt(curEditIndex-1);
							}

						case "ArrowRight", "Delete":
							if( curEditIndex<blocks.length-1 && i.selectionStart==curInput.val().length ) {
								ev.stopPropagation();
								applyEdit( curInput.val() );
								if( curInput.val().length==0 )
									selectAt(curEditIndex);
								else
									selectAt(curEditIndex+1);
							}

						case _:
					}
				});
				curInput.blur( _->{
					applyEdit( curInput.val() );
					unselect();
				});

				// Default input value
				curInput.val(v);
				resizeInput();

				// Position cursor
				curInput.focus();
				if( cursorAtStart ) {
					var i : js.html.InputElement = cast curInput.get(0);
					i.setSelectionRange(0,0);
				}
				// else
					// curInput.select();

			case Var(v):
		}

	}


	function applyEdit(v:String) {
		if( curEditIndex>=0 && curEditIndex<blocks.length ) {
			switch blocks[curEditIndex] {
				case Str(_):
					blocks[curEditIndex] = Str(v);

				case Var(_):
					blocks.insert(curEditIndex+1, Str(v));
			}
		}
		else if( curEditIndex<0 )
			blocks.insert(0, Str(v));
		else
			blocks.push( Str(v) );
		onChange( toString() );
	}


	function renderAll() {
		jPattern.empty();

		var idx = 0;
		for(b in blocks) {
			var i = idx;
			switch b {
				case Str(v):
				case Var(v):
					if( idx==0 || blocks[idx-1].getIndex()==Var(null).getIndex() ) {
						// Empty slot before var
						var jBlock = new J('<div class="block str empty fixed"/>');
						jBlock.appendTo(jPattern);
						jBlock.click(_->{
							blocks.insert(i, Str(""));
							renderAll();
							selectAt(i);
						});
					}
			}
			// jQuery block
			var jBlock = new J('<div class="block"/>');
			jBlock.attr("block-idx", idx);
			jBlock.appendTo(jPattern);
			switch b {
				case Str(v):
					jBlock.addClass("str");
					jBlock.append(v);

				case Var(v):
					jBlock.addClass("var");
					jBlock.append('&lt;$v&gt;');
			}
			jBlock.click( (ev:js.jquery.Event)->{
				switch b {
					case Str(v):
						selectAt(i);

					case Var(v):
						selectAt(i);
						// var x = ev.pageX - jBlock.offset().left;
						// if( x < jBlock.outerWidth()*0.5 )
						// 	editAt(i-1);
						// else
						// 	editAt(i);
				}
			});
			idx++;
		}

		// End filler
		var jFiller = new J('<div class="filler fixed"/>');
		jFiller.appendTo(jPattern);
		jFiller.click( _->{
			switch blocks[blocks.length-1] {
				case null, Var(_):
					blocks.push( Str("") );
					renderAll();
					selectAt(blocks.length-1);

				case Str(v):
					selectAt(blocks.length-1);
			}
		} );

		// Sorting
		// JsTools.makeSortable(jPattern, (ev:sortablejs.Sortable.SortableDragEvent)->{
		// 	var moved = blocks.splice(ev.oldIndex,1)[0];
		// 	blocks.insert(ev.newIndex, moved);
		// 	onChange( toString() );
		// 	renderAll();
		// });
	}
}
