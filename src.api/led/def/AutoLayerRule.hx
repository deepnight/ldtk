package led.def;

class AutoLayerRule {
	public var uid(default,null) : Int;

	public var tileIds : Array<Int> = [];
	public var chance : Float = 1.0;
	public var size(default,null): Int;
	var pattern : Array<Int> = [];
	public var seed : Int;
	public var flipX = false;
	public var flipY = false;
	public var breakOnMatch = false;

	var perlinActive = false;
	public var perlinSeed : Int;
	public var perlinScale : Float = 0.2;
	public var perlinOctaves = 2;
	var _perlin(get,default) : Null<hxd.Perlin>;

	// var bitMasksHas : Null< Map<Int, Int> >;
	// var bitMasksNot : Null< Map<Int, Int> >;

	public function new(uid, size) {
		if( !isValidSize(size) )
			throw 'Invalid rule size ${size}x$size';

		this.uid = uid;
		this.size = size;
		perlinSeed = Std.random(9999999);
		seed = Std.random(9999999);
		initPattern();
	}

	inline function isValidSize(size:Int) {
		return size>=3 && size<=7 && size%2!=0;
	}

	inline function get__perlin() {
		if( perlinSeed!=null && _perlin==null ) {
			_perlin = new hxd.Perlin();
			_perlin.normalize = true;
			_perlin.adjustScale(50, 1);
		}

		if( perlinSeed==null && _perlin!=null )
			_perlin = null;

		return _perlin;
	}

	public inline function hasPerlin() return perlinActive;

	public function setPerlin(active:Bool) {
		if( !active ) {
			perlinActive = false;
			_perlin = null;
		}
		else
			perlinActive = true;
	}

	public function isSymetricX() {
		for( cx in 0...Std.int(size*0.5) )
		for( cy in 0...size )
			if( pattern[coordId(cx,cy)] != pattern[coordId(size-1-cx,cy)] )
				return false;

		return true;
	}

	public function isSymetricY() {
		for( cx in 0...size )
		for( cy in 0...Std.int(size*0.5) )
			if( pattern[coordId(cx,cy)] != pattern[coordId(cx,size-1-cy)] )
				return false;

		return true;
	}

	public inline function get(cx,cy) {
		return pattern[ coordId(cx,cy) ];
	}

	public inline function set(cx,cy,v) {
		// clearOptim();
		return pattern[ coordId(cx,cy) ] = v;
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
		if( flipX && isSymetricX() )
			flipX = false;

		if( flipY && isSymetricY() )
			flipY = false;

		return {
			uid: uid,
			size: size,
			tileIds: tileIds.copy(),
			chance: JsonTools.writeFloat(chance),
			seed: seed,
			pattern: pattern.copy(), // WARNING: could leak to undo/redo leaks if (one day) pattern contained objects
			flipX: flipX,
			flipY: flipY,
			breakOnMatch: breakOnMatch,

			perlinActive: perlinActive,
			perlinSeed: perlinSeed,
			perlinScale: JsonTools.writeFloat(perlinScale),
			perlinOctaves: perlinOctaves,
		}
	}

	public static function fromJson(dataVersion:Int, json:Dynamic) {
		var r = new AutoLayerRule( json.uid, json.size );
		r.tileIds = json.tileIds;
		r.chance = JsonTools.readFloat(json.chance);
		r.pattern = json.pattern;
		r.seed = JsonTools.readInt(json.seed, 1);
		r.flipX = JsonTools.readBool(json.flipX, false);
		r.flipY = JsonTools.readBool(json.flipY, false);
		r.breakOnMatch = JsonTools.readBool(json.breakOnMatch, false);

		r.perlinActive = JsonTools.readBool(json.perlinActive, false);
		r.perlinScale = JsonTools.readFloat(json.perlinScale, 0.2);
		r.perlinOctaves = JsonTools.readInt(json.perlinOctaves, 2);
		r.perlinSeed = JsonTools.readInt(json.perlinSeed, Std.random(9999999));

		return r;
	}



	public function resize(newSize:Int) {
		if( !isValidSize(newSize) )
			throw 'Invalid rule size ${size}x$size';

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
		for(v in pattern)
			if( v!=0 )
				return false;

		return tileIds.length==0;
	}

	// inline function clearOptim() {
	// 	bitMasksHas = null;
	// 	bitMasksNot = null;
	// }

	// public function optimize(li:led.inst.LayerInstance) {
	// 	bitMasksHas = new Map();
	// 	bitMasksNot = new Map();

	// 	for(idx in 0...li.def.countIntGridValues()) {
	// 		var hasMask = 0;
	// 		var notMask = 0;
	// 		for(i in 0...size*size) {
	// 			if( pattern[i]==idx+1 )
	// 				hasMask = dn.M.setBit(hasMask, i);

	// 			if( pattern[i]==-idx-1 )
	// 				notMask = dn.M.setBit(notMask, i);
	// 		}
	// 		bitMasksHas.set(idx, hasMask);
	// 		bitMasksNot.set(idx, notMask);
	// 	}
	// }


	public function matches(li:led.inst.LayerInstance, cx:Int, cy:Int, dirX=1, dirY=1) {
		if( tileIds.length==0 )
			return false;

		if( chance<=0 || chance<1 && dn.M.randSeedCoords(seed, cx,cy, 100) >= chance*100 )
			return false;

		if( hasPerlin() && _perlin.perlin(perlinSeed, cx*perlinScale, cy*perlinScale, perlinOctaves) < 0 )
			return false;

		// Checks if this rule cares about the cell IntGrid value
		var iv = li.getIntGrid(cx,cy);
		var used = false;
		for(v in pattern)
			if( dn.M.iabs(v)==iv+1 || dn.M.iabs(v)==Const.AUTO_LAYER_ANYTHING+1 ) {
				used = true;
				break;
			}
		if( !used )
			return false;

		// Rule check
		var radius = Std.int( size/2 );
		for(px in 0...size)
		for(py in 0...size) {
			var coordId = px + py*size;
			if( pattern[coordId]==0 )
				continue;

			if( !li.isValid(cx+dirX*(px-radius), cy+dirY*(py-radius)) )
				return false;

			if( dn.M.iabs( pattern[coordId] ) == Const.AUTO_LAYER_ANYTHING+1 ) {
				// "Anything" checks
				if( pattern[coordId]>0 && !li.hasIntGrid(cx+dirX*(px-radius), cy+dirY*(py-radius)) )
					return false;

				if( pattern[coordId]<0 && li.hasIntGrid(cx+dirX*(px-radius), cy+dirY*(py-radius)) )
					return false;
			}
			else {
				// Specific value checks
				if( pattern[coordId]>0 && li.getIntGrid(cx+dirX*(px-radius), cy+dirY*(py-radius))!=pattern[coordId]-1 )
					return false;

				if( pattern[coordId]<0 && li.getIntGrid(cx+dirX*(px-radius), cy+dirY*(py-radius))==-pattern[coordId]-1 )
					return false;
			}
		}
		return true;
	}

}