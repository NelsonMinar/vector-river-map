// Load data tiles using the JQuery ajax function
L.TileLayer.Ajax = L.TileLayer.extend({
    _requests: [],
    _data: [],
    data: function () {
        for (var t in this._tiles) {
            var tile = this._tiles[t];
            if (!tile.processed) {
                this._data = this._data.concat(tile.datum);
                tile.processed = true;
            }
        }
        return this._data;
    },
    _addTile: function(tilePoint, container) {
        var tile = { datum: null, processed: false };
        this._tiles[tilePoint.x + ':' + tilePoint.y] = tile;
        this._loadTile(tile, tilePoint);
    },
    // XMLHttpRequest handler; closure over the XHR object, the layer, and the tile
    _xhrHandler: function (req, layer, tile) {
        return function() {
            if (req.readyState != 4) {
                return;
            }
            var s = req.status;
            if ((s >= 200 && s < 300) || s == 304) {
                tile.datum = JSON.parse(req.responseText);
                layer._tileLoaded();
            } else {
                layer._tileLoaded();
            }
        }
    },
    // Load the requested tile via AJAX
    _loadTile: function (tile, tilePoint) {
        var layer = this;
        var req = new XMLHttpRequest();
        this._requests.push(req);
        req.onreadystatechange = this._xhrHandler(req, layer, tile);
        req.open('GET', this.getTileUrl(tilePoint), true);
        req.send();
    },
    _resetCallback: function() {
        this._data = [];
        L.TileLayer.prototype._resetCallback.apply(this, arguments);
        for (var i in this._requests) {
            this._requests[i].abort();
        }
        this._requests = [];
    },
    _update: function() {
        if (this._map._panTransition && this._map._panTransition._inProgress) { return; }
        if (this._tilesToLoad < 0) this._tilesToLoad = 0;
        L.TileLayer.prototype._update.apply(this, arguments);
    }
});

L.TileLayer.GeoJSON = L.TileLayer.Ajax.extend({
    _geojson: {"type":"FeatureCollection","features":[]},
    initialize: function (url, options, geojsonOptions) {
        L.TileLayer.Ajax.prototype.initialize.call(this, url, options);
        this.geojsonLayer = new L.GeoJSON(this._geojson, geojsonOptions);
        this.geojsonOptions = geojsonOptions;
    },
    onAdd: function (map) {
        this._map = map;
        L.TileLayer.Ajax.prototype.onAdd.call(this, map);
        this.on('load', this._tilesLoaded);
        map.addLayer(this.geojsonLayer);
    },
    onRemove: function (map) {
        map.removeLayer(this.geojsonLayer);
        this.off('load', this._tilesLoaded);
        L.TileLayer.Ajax.prototype.onRemove.call(this, map);
    },
    data: function () {
        this._geojson.features = [];
        if (this.options.unique) {
            this._uniqueKeys = {};
        }
        var tileData = L.TileLayer.Ajax.prototype.data.call(this);
        for (var t in tileData) {
            var tileDatum = tileData[t];
            if (tileDatum && tileDatum.features) {

                // deduplicate features by using the string result of the unique function
                if (this.options.unique) {
                    for (var f in tileDatum.features) {
                        var featureKey = this.options.unique(tileDatum.features[f]);
                        if (this._uniqueKeys.hasOwnProperty(featureKey)) {
                            delete tileDatum.features[f];
                        }
                        else {
                            this._uniqueKeys[featureKey] = featureKey;
                        }
                    }
                }
                this._geojson.features =
                    this._geojson.features.concat(tileDatum.features);
            }
        }
        return this._geojson;
    },
    _resetCallback: function () {
        this._geojson.features = [];
        L.TileLayer.Ajax.prototype._resetCallback.apply(this, arguments);
    },
    _tilesLoaded: function (evt) {
        this.geojsonLayer.clearLayers().addData(this.data());
    }
});
