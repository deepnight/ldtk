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

	public function new(cur:String, onChange:String->Void, onReset:Void->String) {
		this.onChange = onChange;
		jEditor = new J('<div class="filePatternEditor"/>');

		jPattern = new J('<div class="pattern"/>');
		jPattern.appendTo(jEditor);

		var jReset = new J('<button class="gray">Reset</button>');
		jReset.appendTo(jEditor);
		jReset.click( _->{
			ofString( onReset() );
		});

		jExample = new J('<div class="example"/>');
		jExample.appendTo(jEditor);

		ofString(cur);
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

	public function toString() {
		var out = "";
		for(b in blocks)
			out += switch b {
				case Str(v): v;
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


	function stopEdit() {
		curEditIndex = null;

		if( curInput!=null ) {
			curInput.remove();
			curInput = null;
		}

		jPattern.find(".selected").removeClass("selected");
	}

	function editAt(idx:Int, cursorAtStart=false) {
		stopEdit();
		curEditIndex = idx;

		if( curEditIndex>=0 && curEditIndex<blocks.length ) {
			var b = blocks[curEditIndex];
			switch b {
				case Str(v):
				case Var(v):
					var next = blocks[curEditIndex+1];
					if( next!=null && next.getIndex()==Str(null).getIndex() ) {
						editAt(curEditIndex+1, true);
						return;
					}
			}

			var jBlock = getBlock(curEditIndex);
			jBlock.addClass("selected");

			// Create input
			curInput = new J('<input type="text"/>');
			curInput.insertAfter(jBlock);
			curInput.on("input", _->{
				resizeInput();
			});
			curInput.keydown( (ev:js.jquery.Event)->{
				switch ev.key {
					case "Escape", "Enter":
						ev.preventDefault();
						ev.stopPropagation();
						curInput.blur();

					case _:
				}
			});
			curInput.blur( _->{
				applyEdit( curInput.val() );
				stopEdit();
			});

			switch b {
				case Str(v):
					curInput.val(v);

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
		}
		else if( curEditIndex<0 ) {
			// Pre-edit
		}
		else {
			// Post-edit
			editAt(blocks.length-1);
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
			var i = idx;
			jBlock.click( (ev:js.jquery.Event)->{
				switch b {
					case Str(v):
						editAt(i);

					case Var(v):
						var x = ev.pageX - jBlock.offset().left;
						if( x < jBlock.outerWidth()*0.5 )
							editAt(i-1);
						else
							editAt(i);
				}
			});
			idx++;
		}

		var jFiller = new J('<div class="filler"/>');
		jFiller.appendTo(jPattern);
		jFiller.click( _->editAt(blocks.length) );
	}
}
