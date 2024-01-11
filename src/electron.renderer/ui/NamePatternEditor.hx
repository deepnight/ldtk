package ui;

enum PatternBlock {
	Empty;
	Str(v:String);
	Var(v:String);
}


class NamePatternEditor {
	static var SEP = "%";

	public var jEditor : js.jquery.JQuery;
	var eventId : String;
	var jPattern : js.jquery.JQuery;
	var onChange : String->Void;
	var onReset: Void->Void;
	var blocks : Array<PatternBlock>;
	var stocks : Array<{ k:String, displayName:String, ?desc:String }> = [];

	var curInput : Null<js.jquery.JQuery>;
	var curEditIndex : Null<Int>;


	public function new(eventId:String, cur:String, stocks, onChange:String->Void, onReset:Void->Void) {
		this.eventId = eventId;
		this.stocks = stocks;
		this.onChange = onChange;
		this.onReset = onReset;
		jEditor = new J('<div class="namePatternEditor"/>');

		jPattern = new J('<div class="pattern"/>');
		jPattern.appendTo(jEditor);

		var jAdd = new J('<button class="add gray"> <span class="icon add"></span> </button>');
		jAdd.appendTo(jEditor);

		var jReset = new J('<a class="reset">[reset]</a>');
		jReset.appendTo(jEditor);

		App.ME.jBody.off(".patternEditor_"+eventId);
		App.ME.jBody.on("keydown.patternEditor_"+eventId, onKey);
		ofString(cur);
		renderAll();
	}


	function onKey(ev:js.jquery.Event) {
		if( jEditor.closest("body").length==0 ) {
			App.ME.jBody.off(".patternEditor_"+eventId);
			return;
		}

		if( curEditIndex==null || blocks.length==0 )
			return;

		switch blocks[curEditIndex] {
			case Str(_), Empty:
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
						onChange( toString() );
						if( curEditIndex>=blocks.length && blocks.length>0 )
							selectAt(blocks.length-1);
						else if( curEditIndex<blocks.length )
							selectAt(curEditIndex-1, ev.key=="Backspace");
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
				for(b in stocks)
					if( remain.indexOf(SEP+b.k)==0 ) {
						blocks.push( Var(b.k) );
						remain = remain.substr(SEP.length + b.k.length);
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

		// Add empty blocks
		if( blocks.length==0 || isVar(blocks.length-1) )
			blocks.push(Empty);
		if( isVar(0) )
			blocks.insert(0, Empty);
		var i = 0;
		while( i<blocks.length ) {
			if( isVar(i) && isVar(i-1) )
				blocks.insert(i, Empty);
			i++;
		}

		renderAll();
	}


	function cleanupFileName(str:String) {
		var reg = ~/[ \/\\.%$:?"<>|*]/gim;
		return reg.replace(str, "_");
	}

	public function toString() {
		var out = "";
		for(b in blocks)
			out += switch b {
				case Empty: "";
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

		App.ME.jBody.find(".namePatternEditor .selected").removeClass("selected");
	}

	function selectAt(idx:Int, cursorAtStart=false) {
		var old = curEditIndex;
		unselect();
		curEditIndex = idx;
		var b = blocks[curEditIndex];

		var jBlock = getBlock(curEditIndex);
		jBlock.addClass("selected");

		switch b {
			case Empty, Str(_):
				// Create input
				curInput = new J('<input type="text"/>');
				curInput.insertAfter(jBlock);

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
								selectAt(curEditIndex-1);
							}

						case "ArrowRight", "Delete":
							if( curEditIndex<blocks.length-1 && i.selectionStart>=curInput.val().length ) {
								ev.stopPropagation();
								applyEdit( curInput.val() );
								renderAll();
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
				switch b {
					case Empty:
					case Str(v): curInput.val(v);
					case Var(v):
				}
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

		if( old==curEditIndex && isVar(curEditIndex) )
			openVariableMenu(jBlock, curEditIndex);
	}


	function applyEdit(v:String) {
		var old = toString();
		if( curEditIndex>=0 && curEditIndex<blocks.length ) {
			switch blocks[curEditIndex] {
				case Str(_), Empty:
					blocks[curEditIndex] = Str(v);

				case Var(_):
					blocks.insert(curEditIndex+1, Str(v));
			}
		}
		else if( curEditIndex<0 )
			blocks.insert(0, Str(v));
		else
			blocks.push( Str(v) );

		if( old!=toString() )
			onChange( toString() );
	}

	inline function isVar(idx:Int) {
		return idx>=0  &&  idx<blocks.length  && blocks[idx].getIndex() == Var(null).getIndex();
	}


	function openVariableMenu(jNear:js.jquery.JQuery, ?replaceIndex:Int) {
		var usedMap = new Map();
		for(b in blocks)
			switch b {
				case Empty:
				case Str(v):
				case Var(v):
					usedMap.set(v,true);
			}

		var ctxAct : Array<ui.modal.ContextMenu.ContextAction> = [];
		for(s in stocks)
			if( !usedMap.exists(s.k))
				ctxAct.push({
					label: L.untranslated(s.displayName),
					subText: L.untranslated(s.desc),
					cb: ()->{
						if( replaceIndex!=null ) {
							blocks[replaceIndex] = Var(s.k);
							onChange( toString() );
							unselect();
							selectAt(replaceIndex);
						}
						else {
							blocks.push( Var(s.k) );
							onChange( toString() );
							selectAt(blocks.length-1);
						}
					},
				});

		if( ctxAct.length>0 ) {
			var ctx = new ui.modal.ContextMenu(jNear);
			for(a in ctxAct)
				ctx.addAction(a);
		}
	}



	function renderAll() {
		jPattern.empty();

		// Blocks
		var idx = 0;
		for(b in blocks) {
			var i = idx;

			// jQuery block
			var jBlock = new J('<div class="block"/>');
			jBlock.attr("block-idx", idx);
			jBlock.appendTo(jPattern);
			if( idx==blocks.length-1 )
				jBlock.addClass("last");
			switch b {
				case Empty:
					jBlock.addClass("str empty");

				case Str(v):
					jBlock.addClass("str draggable");
					jBlock.append(v);

				case Var(v):
					jBlock.addClass("var draggable");
					for(s in stocks)
						if( s.k==v ) {
							jBlock.append(s.displayName);
							break;
						}
			}

			// Selection
			jBlock.click( (ev:js.jquery.Event)->{
				selectAt(i);
			});

			idx++;
		}

		// Other buttons
		jEditor.find(".add").click( (ev:js.jquery.Event)->openVariableMenu( new J(ev.currentTarget)) );
		jEditor.find(".reset").click( _->{
			onReset();
		});

		// Sorting
		JsTools.makeSortable(jPattern, (ev:sortablejs.Sortable.SortableDragEvent)->{
			var moved = blocks.splice(ev.oldIndex,1)[0];
			if( moved==null )
				return;
			blocks.insert(ev.newIndex, moved);
			onChange( toString() );
			renderAll();
		}, { onlyDraggables:true });
	}
}
