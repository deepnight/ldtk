package data.def;

class AutoLayerRuleDef {
	#if heaps // Required to avoid doc generator to explore code too deeply

	@:allow(data.def.LayerDef, data.Definitions)
	public var uid(default,null) : Int;

	public var tileIds : Array<Int> = [];
	public var chance : Float = 1.0;
	public var breakOnMatch = true;
	public var size(default,null): Int;
	var pattern : Array<Int> = [];
	public var alpha = 1.;
	public var outOfBoundsValue : Null<Int>;
	public var flipX = false;
	public var flipY = false;
	public var active = true;
	public var tileMode : ldtk.Json.AutoLayerRuleTileMode = Single;
	public var pivotX = 0.;
	public var pivotY = 0.;
	public var xModulo = 1;
	public var yModulo = 1;
	public var xOffset = 0;
	public var yOffset = 0;
	public var tileXOffset = 0;
	public var tileYOffset = 0;
	public var tileRandomXMin = 0;
	public var tileRandomXMax = 0;
	public var tileRandomYMin = 0;
	public var tileRandomYMax = 0;
	public var checker : ldtk.Json.AutoLayerRuleCheckerMode = None;

	var perlinActive = false;
	public var perlinSeed : Int;
	public var perlinScale : Float = 0.2;
	public var perlinOctaves = 2;
	var _perlin(get,null) : Null<hxd.Perlin>;

	public function new(uid, size=3) {
		if( !isValidSize(size) )
			throw 'Invalid rule size ${size}x$size';

		this.uid = uid;
		this.size = size;
		perlinSeed = Std.random(9999999);
		initPattern();
	}

	public inline function hasAnyPositionOffset() {
		return tileRandomXMin!=0 || tileRandomXMax!=0 || tileRandomYMin!=0 || tileRandomYMax!=0 || tileXOffset!=0 || tileYOffset!=0;
	}

	inline function isValidSize(size:Int) {
		return size>=1 && size<=Const.MAX_AUTO_PATTERN_SIZE && size%2!=0;
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
		return isValid(cx,cy) ? pattern[ coordId(cx,cy) ] = v : 0;
	}

	public inline function fill(v:Int) {
		for(cx in 0...size)
		for(cy in 0...size)
			set(cx,cy,v);
	}

	function initPattern() {
		pattern = [];
		for(i in 0...size*size)
			pattern[i] = 0;
	}

	@:keep public function toString() {
		return 'Rule#$uid(${size}x$size)';
	}

	public function toJson() : ldtk.Json.AutoRuleDef {
		tidy();

		return {
			uid: uid,
			active: active,
			size: size,
			tileIds: tileIds.copy(),
			alpha: alpha,
			chance: JsonTools.writeFloat(chance),
			breakOnMatch: breakOnMatch,
			pattern: pattern.copy(), // WARNING: could leak to undo/redo leaks if (one day) pattern contained objects
			flipX: flipX,
			flipY: flipY,
			xModulo: xModulo,
			yModulo: yModulo,
			xOffset: xOffset,
			yOffset: yOffset,
			tileXOffset: tileXOffset,
			tileYOffset: tileYOffset,
			tileRandomXMin: tileRandomXMin,
			tileRandomXMax: tileRandomXMax,
			tileRandomYMin: tileRandomYMin,
			tileRandomYMax: tileRandomYMax,
			checker: JsonTools.writeEnum(checker, false),
			tileMode: JsonTools.writeEnum(tileMode, false),
			pivotX: JsonTools.writeFloat(pivotX),
			pivotY: JsonTools.writeFloat(pivotY),
			outOfBoundsValue: outOfBoundsValue,

			perlinActive: perlinActive,
			perlinSeed: perlinSeed,
			perlinScale: JsonTools.writeFloat(perlinScale),
			perlinOctaves: perlinOctaves,
		}
	}

	public static function fromJson(jsonVersion:String, json:ldtk.Json.AutoRuleDef) {
		var r = new AutoLayerRuleDef( json.uid, json.size );
		r.active = JsonTools.readBool(json.active, true);
		r.tileIds = json.tileIds;
		r.breakOnMatch = JsonTools.readBool(json.breakOnMatch, false); // default to FALSE to avoid breaking old maps
		r.chance = JsonTools.readFloat(json.chance);
		r.pattern = json.pattern;
		r.alpha = JsonTools.readFloat(json.alpha, 1);
		r.outOfBoundsValue = JsonTools.readNullableInt(json.outOfBoundsValue);
		r.flipX = JsonTools.readBool(json.flipX, false);
		r.flipY = JsonTools.readBool(json.flipY, false);
		r.checker = JsonTools.readEnum(ldtk.Json.AutoLayerRuleCheckerMode, json.checker, false, None);
		r.tileMode = JsonTools.readEnum(ldtk.Json.AutoLayerRuleTileMode, json.tileMode, false, Single);
		r.pivotX = JsonTools.readFloat(json.pivotX, 0);
		r.pivotY = JsonTools.readFloat(json.pivotY, 0);
		r.xModulo = JsonTools.readInt(json.xModulo, 1);
		r.yModulo = JsonTools.readInt(json.yModulo, 1);
		r.xOffset = JsonTools.readInt(json.xOffset, 0);
		r.yOffset = JsonTools.readInt(json.yOffset, 0);
		r.tileXOffset = JsonTools.readInt(json.tileXOffset, 0);
		r.tileYOffset = JsonTools.readInt(json.tileYOffset, 0);
		r.tileRandomXMin = JsonTools.readInt(json.tileRandomXMin, 0);
		r.tileRandomXMax = JsonTools.readInt(json.tileRandomXMax, 0);
		r.tileRandomYMin = JsonTools.readInt(json.tileRandomYMin, 0);
		r.tileRandomYMax = JsonTools.readInt(json.tileRandomYMax, 0);

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
	inline function isValid(cx,cy) {
		return cx>=0 && cx<size && cy>=0 && cy<size;
	}

	public function trim() {
		while( size>1 ) {
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

	public function isUsingUnknownIntGridValues(ld:LayerDef) {
		if( ld.type!=IntGrid )
			throw "Invalid layer type";

		var v = 0;
		for(px in 0...size)
		for(py in 0...size) {
			v = dn.M.iabs( pattern[px+py*size] );
			if( v!=0 && v!=Const.AUTO_LAYER_ANYTHING && !ld.hasIntGridValue(v) )
				return true;
		}

		return false;
	}

	public function matches(li:data.inst.LayerInstance, source:data.inst.LayerInstance, cx:Int, cy:Int, dirX=1, dirY=1) {
		if( tileIds.length==0 )
			return false;

		if( chance<=0 || chance<1 && dn.M.randSeedCoords(li.seed+uid, cx,cy, 100) >= chance*100 )
			return false;

		if( hasPerlin() && _perlin.perlin(li.seed+perlinSeed, cx*perlinScale, cy*perlinScale, perlinOctaves) < 0 )
			return false;

		// Rule check
		// var isOutOfBounds = false;
		var value : Null<Int> = 0;
		var radius = Std.int( size/2 );
		for(px in 0...size)
		for(py in 0...size) {
			var coordId = px + py*size;
			if( pattern[coordId]==0 )
				continue;

			// isOutOfBounds = !source.isValid( cx+dirX*(px-radius), cy+dirY*(py-radius) );
			value = source.isValid( cx+dirX*(px-radius), cy+dirY*(py-radius) )
				? source.getIntGrid( cx+dirX*(px-radius), cy+dirY*(py-radius) )
				: outOfBoundsValue;

			if( value==null )
				return false;
			// if( !source.isValid(cx+dirX*(px-radius), cy+dirY*(py-radius)) )
			// 	return false;

			if( dn.M.iabs( pattern[coordId] ) == Const.AUTO_LAYER_ANYTHING ) {
				// "Anything" checks
				if( pattern[coordId]>0 && value==0 )
					return false;

				if( pattern[coordId]<0 && value!=0 )
					return false;
			}
			else {
				// Specific value checks
				if( pattern[coordId]>0 && value != pattern[coordId] )
					return false;

				if( pattern[coordId]<0 && value == -pattern[coordId] )
					return false;
			}
		}
		return true;
	}

	public function tidy() {
		var anyFix = false;

		if( flipX && isSymetricX() ) {
			App.LOG.add("tidy", 'Fixed X symetry of Rule#$uid');
			flipX = false;
			anyFix = true;
		}

		if( flipY && isSymetricY() ) {
			App.LOG.add("tidy", 'Fixed Y symetry of Rule#$uid');
			flipY = false;
			anyFix = true;
		}

		if( xModulo==1 && yModulo==1 && checker!=None ) {
			App.LOG.add("tidy", 'Fixed checker mode of Rule#$uid');
			checker = None;
			anyFix = true;
		}

		if( xModulo==1 && checker==Horizontal ) {
			App.LOG.add("tidy", 'Fixed checker mode of Rule#$uid');
			checker = yModulo>1 ? Vertical : None;
			anyFix = true;
		}

		if( yModulo==1 && checker==Vertical ) {
			App.LOG.add("tidy", 'Fixed checker mode of Rule#$uid');
			checker = xModulo>1 ? Horizontal : None;
			anyFix = true;
		}

		if( trim() )
			anyFix = true;

		return anyFix;
	}

	public function getRandomTileForCoord(seed:Int, cx:Int,cy:Int) : Int {
		return tileIds[ dn.M.randSeedCoords( uid+seed, cx,cy, tileIds.length ) ];
	}

	public function getXOffsetForCoord(seed:Int, cx:Int,cy:Int, flips:Int) : Int {
		return ( M.hasBit(flips,0)?-1:1 ) * ( tileXOffset + (
			tileRandomXMin==0 && tileRandomXMax==0
				? 0
				: dn.M.randSeedCoords( uid+seed, cx,cy, (tileRandomXMax-tileRandomXMin+1) ) + tileRandomXMin
		));
	}

	public function getYOffsetForCoord(seed:Int, cx:Int,cy:Int, flips:Int) : Int {
		return ( M.hasBit(flips,1)?-1:1 ) * ( tileYOffset + (
			tileRandomYMin==0 && tileRandomYMax==0
				? 0
				: dn.M.randSeedCoords( uid+seed+1, cx,cy, (tileRandomYMax-tileRandomYMin+1) ) + tileRandomYMin
		));
	}

	#end
}