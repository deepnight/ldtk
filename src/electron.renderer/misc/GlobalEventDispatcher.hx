package misc;

class GlobalEventDispatcher {
	var anyListeners : Array<GlobalEvent->Void> = [];
	var specificListeners : Array<{ e:GlobalEvent, cb:Void->Void }> = [];
	var eofEvents : Map<GlobalEvent,Bool> = [];

	public function new() {
	}

	public function addSpecificListener(e:GlobalEvent, onEvent:Void->Void) {
		specificListeners.push({ e:e, cb:onEvent });
	}

	public function addGlobalListener(onEvent:GlobalEvent->Void) {
		anyListeners.push(onEvent);
	}

	public function removeListener(?any:GlobalEvent->Void, ?specific:Void->Void) {
		if( any!=null )
			anyListeners.remove(any);

		if( specific!=null ) {
			for(l in specificListeners)
				if( l.cb==specific ) {
					specificListeners.remove(l);
					break;
				}
		}
	}

	public function emit(e:GlobalEvent) {
		for(ev in anyListeners)
			ev(e);

		for(l in specificListeners)
			if( l.e.getIndex()==e.getIndex() )
				l.cb();
	}

	public function emitAtTheEndOfFrame(e:GlobalEvent) {
		eofEvents.set(e,true);
	}

	public function onEndOfFrame() {
		for(e in eofEvents.keys()) {
			eofEvents.remove(e);
			emit(e);
		}
	}

	public function dispose() {
		anyListeners = null;
	}
}