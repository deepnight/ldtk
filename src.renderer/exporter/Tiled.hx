package exporter;

import led.Json;

class Tiled {
	static var TILED_VERSION = "1.4.2";
	static var MAP_VERSION = "1.4";

	public static var LOG = new dn.Log(100);
	public static function export(p:led.Project) : haxe.io.Bytes {
		LOG.clear();
		LOG.general("Converting project...");
		return exportLevel(p, p.levels[0]);
	}


	public static function verify(p:led.Project) {} // TODO should return recommendations & issues


	static function exportLevel(p:led.Project, level:led.Level) : haxe.io.Bytes {
		LOG.general("Converting level "+level.identifier+"...");
		var xml = Xml.createDocument();
		var layerId = 1;
		var objectId = 1;
		var gid = 1;

		/**
			Tiled a unique "grid size" value because it doesn't support different
			grid sizes in the same map file. So let's invent some arbitrary grid size
			for it to be happy :facepalm:
		**/
		var mapGrid = level.layerInstances.length==0 ? p.defaultGridSize : Const.INFINITE;
		for(li in level.layerInstances)
			mapGrid = M.imin(mapGrid, li.def.gridSize);
		var mapWidth = M.ceil( level.pxWid/mapGrid );
		var mapHeight = M.ceil( level.pxHei/mapGrid );

		/**
			MAP

			<map version="1.2" tiledversion="1.3.1" orientation="orthogonal" renderorder="right-down" compressionlevel="0" width="200" height="200" tilewidth="8" tileheight="8" infinite="0" backgroundcolor="#171c39" nextlayerid="35" nextobjectid="272">
		**/
		var map = Xml.createElement("map");
		xml.addChild(map);
		map.set("version", MAP_VERSION);
		map.set("tiledversion", TILED_VERSION);
		map.set("orientation", "orthogonal");
		map.set("renderorder", "right-down");
		map.set("compressionlevel", "0");
		map.set("width", ""+mapWidth);
		map.set("height", ""+mapHeight);
		map.set("tilewidth", ""+mapGrid);
		map.set("tileheight", ""+mapGrid);
		map.set("infinite", "0");
		map.set("backgroundcolor", C.intToHex(p.bgColor));
		map.set("nextobjectid", "1"); // TODO


		/**
			TILESETS

			<tileset firstgid="1" name="cavesofgallet_tiles" tilewidth="8" tileheight="8" tilecount="384" columns="12">
				<image source="cavesofgallet_tiles.png" width="96" height="256"/>
			</tileset>
		**/
		var tilesetGids = new Map();
		for( td in p.defs.tilesets ) {
			LOG.general('Adding tileset ${td.identifier}...');
			if( td.padding!=0 )
				LOG.error('Tileset ${td.identifier} has padding, which isn\'t supported by Tiled which sucks bla fbklea lkez klz.');

			var count = M.ceil(td.pxWid/td.tileGridSize) * M.ceil(td.pxHei/td.tileGridSize);
			var tileset = Xml.createElement("tileset");
			map.addChild(tileset);
			tileset.set("firstgid",""+gid);
			tileset.set("name", td.identifier);
			tileset.set("tilewidth", ""+td.tileGridSize);
			tileset.set("tileheight", ""+td.tileGridSize);
			tileset.set("tilecount", "" + count);
			tileset.set("columns", "" + M.ceil(td.pxWid/td.tileGridSize) );
			tileset.set("objectalignment", "topleft" );
			tileset.set("margin", "0" );
			tileset.set("spacing", ""+td.spacing );

			LOG.general('  Adding image ${td.relPath}...');
			var image = Xml.createElement("image");
			tileset.addChild(image);
			image.set("source", td.relPath);
			image.set("width", ""+td.pxWid);
			image.set("height", ""+td.pxHei);

			tilesetGids.set(td.uid, gid);
			gid+=count;
		}

		function _remapTileId(tilesetUid:Int, tileId:Int, flips=0) : UInt {
			if( flips==0 )
				return tilesetGids.get(tilesetUid) + tileId;
			else {
				var gid : UInt = tilesetGids.get(tilesetUid) + tileId;

				if( M.hasBit(flips,0) )
					gid = M.setUnsignedBit(gid, 31);

				if( M.hasBit(flips,1) )
					gid = M.setUnsignedBit(gid, 30);

				return gid;
			}
		}


		/**
			LAYERS

			<layer id="32" name="collisions" width="200" height="200" opacity="0.79">
				<properties>
					<property name="advColl" type="bool" value="true"/>
				</properties>
				<data encoding="csv">...</data>
			</layer>
		**/
		function _createLayer(type:String, li:led.inst.LayerInstance, nameSuffix="") {
			var layer = Xml.createElement(type);
			map.addChild(layer);
			layer.set("id", Std.string(layerId++));
			layer.set("name", li.def.identifier + nameSuffix);
			switch type {
				case "layer":
					layer.set("width",""+li.cWid);
					layer.set("height",""+li.cHei);
					layer.set("opacity",""+li.def.displayOpacity);

				case "objectgroup":
			}
			return layer;
		}

		for(li in level.layerInstances) {
			var ld = p.defs.layers.filter( (ld)->ld.uid==li.layerDefUid )[0];
			LOG.general("Layer "+ld.identifier+"...");


			switch ld.type {
				case IntGrid:
					if( ld.autoTilesetDefUid==null && ld.gridSize!=mapGrid ) {
						LOG.error("IntGrid layer "+ld.identifier+" was not exported because it has a different gridSize (not supported by Tiled).");
						continue;
					}

					// IntGrid values
					LOG.general("  Exporting IntGrid values...");
					var layer = _createLayer("layer", li, "_values");
					var data = Xml.createElement("data");
					layer.addChild(data);
					data.set("encoding","csv");
					var csv = new Csv(li.cWid, li.cHei);
					for(cy in 0...li.cHei)
					for(cx in 0...li.cWid)
						if( li.hasIntGrid(cx,cy) )
							csv.set(cx,cy, li.getIntGrid(cx,cy)+1);
					data.addChild( Xml.createPCData(csv.getString()) );

				case Entities:
				case Tiles:
				case AutoLayer:
			}


			// Auto-layer tiles
			if( ld.autoTilesetDefUid!=null ) {
				LOG.general("  Exporting Auto-Layer tiles...");
				var layer = _createLayer("objectgroup", li, "_tiles");

				var td = p.defs.getTilesetDef(ld.autoTilesetDefUid);

				var json = li.toJson(); // much easier to rely on JSON here
				for(at in json.autoTiles)
				for(r in at.results)
				for(t in r.tiles) {
					var o = Xml.createElement("object");
					layer.insertChild(o,0);
					o.set("id", Std.string(objectId++));
					o.set("gid", ""+_remapTileId(ld.autoTilesetDefUid, t.tileId, r.flips));
					o.set("x", ""+t.__x);
					o.set("y", ""+t.__y);
					o.set("width", ""+td.tileGridSize);
					o.set("height", ""+td.tileGridSize);
				}
			}
		}

		map.set("nextlayerid", ""+layerId);

		return haxe.io.Bytes.ofString( xml.toString() );
	}
}


private class Csv {
	var wid: Int;
	var hei: Int;
	var bytes: haxe.io.Bytes;

	public function new(w,h) {
		wid = w;
		hei = h;
		bytes = haxe.io.Bytes.alloc(wid*hei);
		bytes.fill(0, bytes.length, 0);
		trace('$wid x $hei => ${bytes.length}');
	}

	public inline function set(cx,cy, v:Int) {
		if( cx>=0 && cy>=0 )
			setCoordId(cx+cy*wid, v);
	}

	public inline function setCoordId(coordId, v:Int) {
		if( coordId<wid*hei )
			bytes.set(coordId, v);
	}

	public function getString() {
		var out = [];
		for(cy in 0...hei)
		for(cx in 0...wid)
			out.push( bytes.get(cx+cy*wid) );
		return out.join(",");
	}
}
