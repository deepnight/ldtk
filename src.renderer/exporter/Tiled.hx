package exporter;

import led.Json;

class Tiled {
	public static function convert(p:led.Json.ProjectJson) : haxe.io.Bytes {
		var xml = Xml.createDocument();

		// Map node
		/**
			<map version="1.2" tiledversion="1.3.1" orientation="orthogonal" renderorder="right-down" compressionlevel="0" width="200" height="200" tilewidth="8" tileheight="8" infinite="0" backgroundcolor="#171c39" nextlayerid="35" nextobjectid="272">
		**/
		var map = Xml.createElement("map");
		xml.addChild(map);
		map.set("version", "1.2");
		map.set("tiledversion", "1.3.1");
		map.set("orientation", "orthogonal");
		map.set("renderorder", "right-down");
		map.set("compressionlevel", "0");
		map.set("width", "256"); // TODO
		map.set("height", "256"); // TODO
		map.set("tilewidth", ""+p.defaultGridSize);
		map.set("tileheight", ""+p.defaultGridSize);
		map.set("infinite", "0");
		map.set("backgroundcolor", p.bgColor);
		map.set("nextobjectid", "1"); // TODO

		var layerId = 1;
		var gid = 1;

		// Tilesets
		/**
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

			var image = Xml.createElement("image");
			tileset.addChild(image);
			image.set("source", td.relPath);
			image.set("width", ""+td.pxWid);
			image.set("height", ""+td.pxHei);

			tilesetGids.set(td.uid, gid);
			gid+=count;
		}

		function _remapTileId(tilesetUid:Int, tileId:Int) {
			return tilesetGids.get(tilesetUid) + tileId + 1;
		}

		var level = p.levels[0];
		// Layers
		/**
			<layer id="32" name="collisions" width="200" height="200" opacity="0.79">
				<properties>
					<property name="advColl" type="bool" value="true"/>
				</properties>
				<data encoding="csv">...</data>
			</layer>
		**/
		for(li in level.layerInstances) {
			var ld = p.defs.layers.filter( (ld)->ld.uid==li.layerDefUid )[0];
			var layer = Xml.createElement("layer");
			map.addChild(layer);
			layer.set("id", Std.string(layerId++));
			layer.set("name",ld.identifier);
			layer.set("width",""+level.pxWid);
			layer.set("height",""+level.pxHei);
			layer.set("opacity",""+ld.displayOpacity);

			var data = Xml.createElement("data");
			layer.addChild(data);
			data.set("encoding","csv");

			// Auto layer
			if( ld.autoTilesetDefUid!=null ) {
				var csv = [];
				// TODO how to render freely positionned tiles?
				// See: https://doc.mapeditor.org/en/stable/reference/tmx-map-format/#tmx-tilelayer-tile

				for(at in li.autoTiles)
				for(r in at.results)
				for(t in r.tiles) {
					var tile = Xml.createElement("tile");
					data.addChild(tile);
					tile.set("gid", ""+_remapTileId(ld.autoTilesetDefUid, t.tileId));
					// var tileGid = _remapTileId(ld.autoTilesetDefUid, t.tileId);
					// tile.set("x", ""+t.__x);
					// tile.set("y", ""+t.__y);
				}
			}
		}

		map.set("nextlayerid", ""+layerId);

		return haxe.io.Bytes.ofString( xml.toString() );
	}
}