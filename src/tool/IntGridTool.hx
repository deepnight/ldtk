package tool;

class IntGridTool extends Tool<Int> {
	public function new() {
		super();
	}

	override function selectValue(v:Int) {
		v = M.iclamp(v, 0, curLayerInstance.def.countIntGridValues()-1);
		super.selectValue(v);
	}

	override function getDefaultValue():Int {
		return 0;
	}

	inline function getSelectedColor() {
		return curLayerInstance.def.getIntGridValueDef( getSelectedValue() ).color;
	}


	override function updateCursor(m:MouseCoords) {
		super.updateCursor(m);

		if( isRunning() && rectangle ) {
			var r = Rect.fromMouseCoords(origin, m);
			editor.cursor.set( GridRect(curLayerInstance, r.left, r.top, r.wid, r.hei, getSelectedColor()) );
		}
		else if( curLayerInstance.isValid(m.cx,m.cy) )
			editor.cursor.set( GridCell(curLayerInstance, m.cx, m.cy, getSelectedColor()) );
		else
			editor.cursor.set(None);
	}

	override function onMouseMove(m:MouseCoords) {
		super.onMouseMove(m);
	}

	override function useAt(m:MouseCoords) {
		super.useAt(m);

		var anyChange = false;
		dn.Bresenham.iterateThinLine(lastMouse.cx, lastMouse.cy, m.cx, m.cy, function(cx,cy) {
			var old = curLayerInstance.getIntGrid(cx,cy);
			switch curMode {
				case null, PanView:
				case Add:
					curLayerInstance.setIntGrid(cx, cy, getSelectedValue());

				case Remove:
					curLayerInstance.removeIntGrid(cx, cy);

				case Move:
			}
			if( old!=curLayerInstance.getIntGrid(cx,cy) ) {
				editor.curLevelHistory.markChange(cx,cy);
				anyChange = true;
			}
		});

		return anyChange;
	}


	override function useOnRectangle(left:Int, right:Int, top:Int, bottom:Int) {
		super.useOnRectangle(left, right, top, bottom);

		var anyChange = false;
		for(cx in left...right+1)
		for(cy in top...bottom+1) {
			var old = curLayerInstance.getIntGrid(cx,cy);
			switch curMode {
				case null, PanView:
				case Add:
					curLayerInstance.setIntGrid(cx,cy, getSelectedValue());

				case Remove:
					curLayerInstance.removeIntGrid(cx,cy);

				case Move:
			}

			if( old!=curLayerInstance.getIntGrid(cx,cy) ) {
				editor.curLevelHistory.markChange(cx,cy);
				anyChange = true;
			}
		}

		return anyChange;
	}


	override function useFloodfillAt(m:MouseCoords):Bool {
		super.useFloodfillAt(m);

		var li = curLayerInstance;

		var initial = li.getIntGrid(m.cx,m.cy);
		if( initial==getSelectedValue() )
			return false;


		var pending = [{ cx:m.cx, cy:m.cy }];
		var dones = new Map();
		inline function check(cx:Int,cy:Int) {
			if( li.isValid(cx,cy) && !dones.exists(cx+cy*li.cWid) && li.getIntGrid(cx,cy) == initial ) {
				dones.set(cx+cy*li.cWid, true);
				pending.push({ cx:cx, cy:cy });
			}
		}

		while( pending.length>0 ) {
			var cur = pending.pop();

			check(cur.cx-1, cur.cy);
			check(cur.cx+1, cur.cy);
			check(cur.cx, cur.cy-1);
			check(cur.cx, cur.cy+1);

			li.setIntGrid( cur.cx, cur.cy, getSelectedValue() );
		}

		return true;
	}


	override function createPalette() {
		var target = super.createPalette();

		var list = new J('<ul class="niceList"/>');
		list.appendTo(target);

		var idx = 0;
		for( intGridVal in curLayerInstance.def.getAllIntGridValues() ) {
			var e = new J("<li/>");
			e.appendTo(list);
			e.addClass("color");
			if( idx==getSelectedValue() )
				e.addClass("active");

			if( intGridVal.identifier==null )
				e.text("#"+idx);
			else
				e.text("#"+idx+" - "+intGridVal.identifier);

			e.css("color", C.intToHex( C.autoContrast(C.toBlack(intGridVal.color,0.3)) ));
			e.css("background-color", C.intToHex(intGridVal.color));
			var curIdx = idx;
			e.click( function(_) {
				selectValue(curIdx);
				list.find(".active").removeClass("active");
				e.addClass("active");
				updatePalette();
			});
			idx++;
		}

		return target;
	}
}