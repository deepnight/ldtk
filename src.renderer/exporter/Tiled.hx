package exporter;

import led.Json;

class Tiled {
	public static var LOG = new dn.Log(100);
	public static function convert(p:led.Json.ProjectJson) : haxe.io.Bytes {
		LOG.clear();
		LOG.general("Converting project...");
		return convertLevel(p, p.levels[0]);
	}

	public static function verify(p:led.Project) {} // TODO should return recommendations & issues

	public static function convertLevel(p:led.Json.ProjectJson, level:led.Json.LevelJson) : haxe.io.Bytes {
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
			mapGrid = M.imin(mapGrid, li.__gridSize);
		var mapWidth = M.ceil( level.pxWid/mapGrid );
		var mapHeight = M.ceil( level.pxHei/mapGrid );

		/**
			MAP

			<map version="1.2" tiledversion="1.3.1" orientation="orthogonal" renderorder="right-down" compressionlevel="0" width="200" height="200" tilewidth="8" tileheight="8" infinite="0" backgroundcolor="#171c39" nextlayerid="35" nextobjectid="272">
		**/
		var map = Xml.createElement("map");
		xml.addChild(map);
		map.set("version", "1.2");
		map.set("tiledversion", "1.3.1");
		map.set("orientation", "orthogonal");
		map.set("renderorder", "right-down");
		map.set("compressionlevel", "0");
		map.set("width", ""+mapWidth);
		map.set("height", ""+mapHeight);
		map.set("tilewidth", ""+mapGrid);
		map.set("tileheight", ""+mapGrid);
		map.set("infinite", "0");
		map.set("backgroundcolor", p.bgColor);
		map.set("nextobjectid", "1"); // TODO


		/**
			TILESETS

			<tileset firstgid="1" name="cavesofgallet_tiles" tilewidth="8" tileheight="8" tilecount="384" columns="12">
				<image source="cavesofgallet_tiles.png" width="96" height="256"/>
			</tileset>
		**/
		var tilesetGids = new Map();
		for( td in p.defs.tilesets ) {
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


			var image = Xml.createElement("image");
			tileset.addChild(image);
			image.set("source", td.relPath);
			image.set("width", ""+td.pxWid);
			image.set("height", ""+td.pxHei);

			tilesetGids.set(td.uid, gid);
			gid+=count;
		}

		function _remapTileId(tilesetUid:Int, tileId:Int) {
			return tilesetGids.get(tilesetUid) + tileId;
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
		for(li in level.layerInstances) {
			var ld = p.defs.layers.filter( (ld)->ld.uid==li.layerDefUid )[0];
			LOG.general("Layer "+ld.identifier+"...");

			switch ld.__type {
				case "IntGrid":
					if( ld.autoTilesetDefUid==null && ld.gridSize!=mapGrid ) {
						LOG.error("IntGrid layer "+ld.identifier+" wasn't exported because it has a different gridSize (unsupported by Tiled).");
						continue;
					}
			}

			// Layer node
			var layer = Xml.createElement("layer");
			map.addChild(layer);
			layer.set("id", Std.string(layerId++));
			layer.set("name",ld.identifier);
			layer.set("width",""+li.__cWid);
			layer.set("height",""+li.__cHei);
			layer.set("opacity",""+ld.displayOpacity);

			// IntGrid values
			if( ld.__type=="IntGrid" ) {
				LOG.general("  Exporting IntGrid values...");
				var data = Xml.createElement("data");
				layer.addChild(data);
				data.set("encoding","csv");
				var csv = new Csv(li.__cWid, li.__cHei);
				for(iv in li.intGrid)
					csv.setCoordId(iv.coordId, iv.v);
				data.addChild( Xml.createPCData(csv.getString()) );
			}

			// Auto-layer tiles in a separate layer
			if( ld.autoTilesetDefUid!=null ) {
				LOG.general("  Exporting Auto-Layer tiles...");
				var tileLayer = Xml.createElement("objectgroup");
				map.addChild(tileLayer);
				tileLayer.set("id", Std.string(layerId++));
				tileLayer.set("name", ld.identifier+"_Tiles");

				for(at in li.autoTiles)
				for(r in at.results)
				for(t in r.tiles) {
					var o = Xml.createElement("object");
					tileLayer.addChild(o);
					o.set("id", Std.string(objectId++));
					o.set("gid", ""+_remapTileId(ld.autoTilesetDefUid, t.tileId));
					o.set("x", ""+t.__x);
					o.set("y", ""+t.__y);
					o.set("width", ""+ld.gridSize); // HACK
					o.set("height", ""+ld.gridSize); // HACK
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
