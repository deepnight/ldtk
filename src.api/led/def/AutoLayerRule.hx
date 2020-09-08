package led.def;

class AutoLayerRule {
	public var tileIds : Array<Int> = [];
	public var chance : Float = 1.0;
	public var size(default,null): Int; //  TODO private
	public var pattern : Array<Int> = []; // TODO private

	public function new(s) {
		size = s;
		initPattern();
	}

	function initPattern() {
		pattern = [];
		for(i in 0...size*size)
			pattern[i] = 0;
	}

	@:keep public function toString() {
		return 'Rule(${size}x$size):$pattern';
	}

	public function toJson() {
		return {
			tileIds: tileIds.copy(),
			chance: JsonTools.writeFloat(chance),
			size: size,
			pattern: pattern.copy(), // WARNING: could leak to undo/redo leaks if (one day) pattern contained objects
		}
	}

	public static function fromJson(dataVersion:Int, json:Dynamic) {
		var r = new AutoLayerRule( json.size );
		r.tileIds = json.tileIds;
		r.chance = JsonTools.readFloat(json.chance);
		r.pattern = json.pattern;
		return r;
	}



	public function resize(newSize:Int) {
		var oldSize = size;
		var oldPatt = pattern.copy();
		var pad = Std.int( dn.M.iabs(newSize-oldSize) / 2 );

		size = newSize;
		initPattern();
		if( newSize<oldSize ) {
			// Decrease
			for( cx in 0...newSize )
			for( cy in 0...newSize )
				pattern[cx + cy*newSize] = oldPatt[cx+pad + (cy+pad)*oldSize];
		}
		else {
			// Increase
			for( cx in 0...oldSize )
			for( cy in 0...oldSize )
				pattern[cx+pad + (cy+pad)*newSize] = oldPatt[cx + cy*oldSize];
		}

		return true;
	}

	inline function coordId(cx,cy) return cx+cy*size;

	public function trim() {
		while( size>3 ) {
			var emptyBorder = true;
			for( cx in 0...size )
				if( pattern[coordId(cx,0)]!=0 || pattern[coordId(cx,size-1)]!=0 ) {
					emptyBorder = false;
					break;
				}
			for( cy in 0...size )
				if( pattern[coordId(0,cy)]!=0 || pattern[coordId(size-1,cy)]!=0 ) {
					emptyBorder = false;
					break;
				}

			if( emptyBorder )
				resize(size-2);
			else
				return false;
		}

		return true;
	}

	public function isEmpty() {
		if( tileIds.length==0 )
			return true;

		for(v in pattern)
			if( v!=0 )
				return false;

		return true;
	}


	public function matches(li:led.inst.LayerInstance, cx:Int, cy:Int) { // TODO optimize the rule checks!
		if( tileIds.length==0 )
			return false;

		if( chance<=0 || chance<1 && dn.M.randSeedCoords(li.def.randSeed, cx,cy, 100) >= chance*100 )
			return false;

		var radius = Std.int( size/2 );
		for(px in 0...size)
		for(py in 0...size) {
			var coordId = px + py*size;
			if( pattern[coordId]==null )
				continue;

			if( dn.M.iabs( pattern[coordId] ) == Const.AUTO_LAYER_ANYTHING+1 ) {
				// "Anything" checks
				if( pattern[coordId]>0 && !li.hasIntGrid(cx+px-radius,cy+py-radius) )
					return false;

				if( pattern[coordId]<0 && li.hasIntGrid(cx+px-radius,cy+py-radius) )
					return false;
			}
			else {
				// Specific value checks
				if( pattern[coordId]>0 && li.getIntGrid(cx+px-radius,cy+py-radius)!=pattern[coordId]-1 )
					return false;

				if( pattern[coordId]<0 && li.getIntGrid(cx+px-radius,cy+py-radius)==-pattern[coordId]-1 )
					return false;
			}
		}
		return true;
	}

}