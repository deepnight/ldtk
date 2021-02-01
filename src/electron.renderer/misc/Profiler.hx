package misc;

// TODO not used anymore

class Profiler {
	static var timers : Map<String,Float> = new Map();
	static var averages : Map<String,Float> = new Map();

	public static function init() {
		timers = new Map();
		averages = new Map();
	}

	public static inline function beginFrame() {
	}

	public static inline function start(id:String) {
		timers.set(id, now());
	}

	public static inline function end(id:String) {
		if( timers.exists(id) ) {
			var t = now() - timers.get(id);
			timers.remove(id);
			if( !averages.exists(id) )
				averages.set(id, t);
			else
				averages.set(id, (averages.get(id) + t)*0.5);
		}
		timers.set(id, now());
	}

	static inline function now() return haxe.Timer.stamp();

	public static inline function endFrame() {
		App.ME.clearDebug();
		for(a in averages.keyValueIterator())
			App.ME.debug(a.key+" => "+M.pretty(a.value,3)+"s");
	}
}