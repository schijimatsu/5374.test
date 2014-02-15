(function() {
  "use strict";
  var APPID, Mapview, YOLP, broadOrSingle, checkMoreThan, failGetLocation, getAllocationData, getChikuList, getLocation, integrateNumbers, jsonp, loadlib, reverseGeoCode, sample_json, sample_lat, sample_lon, self, successGetLocation;

  YOLP = 'http://reverse.search.olp.yahooapis.jp/OpenLocalPlatform/V1/reverseGeoCoder';

  APPID = 'dj0zaiZpPWowM3hJMjNhNEVhSSZzPWNvbnN1bWVyc2VjcmV0Jng9ODM-';

  sample_lat = 36.55918528912932;

  sample_lon = 136.6466188430786;

  sample_json = "{\"ResultInfo\":{\"Count\":1,\"Total\":1,\"Start\":1,\"Latency\":0.0035960674285889,\"Status\":200,\"Description\":\"指定の地点の住所情報を取得する機能を提供します。\",\"Copyright\":\"Copyright (C) 2014 Yahoo Japan Corporation. All Rights Reserved.\",\"CompressType\":\"\"},\"Feature\":[{\"Property\":{\"Country\":{\"Code\":\"JP\",\"Name\":\"日本\"},\"Address\":\"石川県金沢市菊川２丁目１３\",\"AddressElement\":[{\"Name\":\"石川県\",\"Kana\":\"いしかわけん\",\"Level\":\"prefecture\",\"Code\":\"17\"},{\"Name\":\"金沢市\",\"Kana\":\"かなざわし\",\"Level\":\"city\",\"Code\":\"17201\"},{\"Name\":\"菊川\",\"Kana\":\"きくがわ\",\"Level\":\"oaza\"},{\"Name\":\"２丁目\",\"Kana\":\"２ちょうめ\",\"Level\":\"aza\"},{\"Name\":\"１３\",\"Kana\":\"１３\",\"Level\":\"detail1\"}],\"Building\":[{\"Id\":\"B@llF_pR1sI\",\"Name\":\"\",\"Floor\":\"2\",\"Area\":\"\"}]},\"Geometry\":{\"Type\":\"point\",\"Coordinates\":\"136.65982335805893,36.552413515466455\"}}]}";

  String.prototype.toOneByteAlphaNumeric = function() {
    return this.replace(/[Ａ-Ｚａ-ｚ０-９]/g, function(s) {
      return String.fromCharCode(s.charCodeAt(0) - 0xFEE0);
    });
  };

  integrateNumbers = function(numbers) {
    var number, ret, temp, _i, _len, _ref;
    if (numbers == null) {
      numbers = [];
    }
    temp = [];
    ret = [];
    _ref = numbers.sort(function(a, b) {
      return a - b;
    });
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      number = _ref[_i];
      number -= 0;
      if (temp.length === 0 || temp.slice(-1)[0] + 1 === number) {
        temp.push(number);
      } else {
        ret.push(broadOrSingle(temp));
        temp = [number];
      }
    }
    ret.push(broadOrSingle(temp));
    return ret;
  };

  broadOrSingle = function(list) {
    if (list.length > 1) {
      return "" + list[0] + "〜" + (list.slice(-1)[0]);
    } else {
      return list[0];
    }
  };

  loadlib = function(path) {
    var script;
    script = document.createElement('script');
    script.setAttribute('type', 'text/javascript');
    script.setAttribute('src', path);
    return document.head.appendChild(script);
  };

  jsonp = function(url, data, callback) {
    var k, v;
    console.log("calling jsonp.");
    return $.ajax({
      type: 'GET',
      url: url,
      dataType: 'jsonp',
      data: ((function() {
        var _results;
        _results = [];
        for (k in data) {
          v = data[k];
          _results.push(["" + k + "=" + v]);
        }
        return _results;
      })()).join('&'),
      success: callback
    });
  };

  getLocation = function(success, fail) {
    return navigator.geolocation.getCurrentPosition(success, fail, {
      enableHighAccuracy: true,
      timeout: 5000
    });
  };

  successGetLocation = function(position) {
    console.log("lat: " + position.coords.latitude + ", lon: " + position.coords.longitude + ", accuracy: " + position.coords.accuracy);
    return reverseGeoCode(position.coords.latitude, position.coords.longitude, position.coords.accuracy);
  };

  failGetLocation = function(error) {
    console.log('Error.');
    return console.log(error.message);
  };

  reverseGeoCode = function(lat, lon, accuracy, callback) {
    if (callback == null) {
      callback = null;
    }
    callback = callback || successReverseGeocode;
    console.log(callback);
    return jsonp(YOLP, {
      appid: APPID,
      lat: lat,
      lon: lon,
      output: 'json',
      datum: 'wgs',
      callback: 'successReverseGeocode'
    }, callback);
  };

  getAllocationData = function(address, callback) {
    if (!this.allocation) {
      return $.getJSON('./allocation.json', function(data) {
        this.allocation = data;
        return getChikuList.call(this, address, callback);
      });
    } else {
      return getChikuList.call(this, address, callback);
    }
  };

  checkMoreThan = function(banchi_under, narrowed_allocation) {
    var k, m, prefix, r, v, value;
    r = /^([^0-9]*?)([0-9]+?)〜$/;
    prefix = null;
    value = null;
    for (k in narrowed_allocation) {
      v = narrowed_allocation[k];
      m = r.exec(k);
      if (m) {
        prefix = m[1];
        value = m[2];
        break;
      }
    }
    if ((value !== null) && (banchi_under !== '')) {
      r = /^(-|－)?([^0-9]*?)([0-9]+)$/;
      m = r.exec(banchi_under);
      if (m && (m[3] - 0) >= (value.toOneByteAlphaNumeric() - 0)) {
        if (prefix !== null && prefix === m[2]) {
          return [m[3], prefix + value + '〜'];
        } else {
          return [m[3], value + '〜'];
        }
      } else {
        return null;
      }
    } else {
      return null;
    }
  };

  getChikuList = function(address, callback) {
    var aza, aza_under, banchi, banchi_under, banchis, bu, chiku, gaiku, gaiku_under, list, m, moreThan, name, narrowed_allocation, number, r, _, _i, _len, _ref;
    list = {};
    m = /^石川県金沢市(.*)$/.exec(address);
    if (m) {
      aza_under = m[1];
      m = RegExp("" + ("^(" + (((function() {
        var _ref, _results;
        _ref = this.allocation;
        _results = [];
        for (name in _ref) {
          _ = _ref[name];
          _results.push(name);
        }
        return _results;
      }).call(this)).join('|')) + ")(.*)$")).exec(aza_under);
      if (m) {
        aza = m[1];
        narrowed_allocation = this.allocation[aza];
        gaiku_under = m[2];
        r = RegExp("" + ("^(-|－)*(" + (((function() {
          var _results;
          _results = [];
          for (number in narrowed_allocation) {
            _ = narrowed_allocation[number];
            if (number !== '') {
              _results.push(number);
            }
          }
          return _results;
        })()).sort(function(a, b) {
          return b - a;
        }).join('|')) + ")(.*)$"));
        m = r.exec(gaiku_under.toOneByteAlphaNumeric());
        if (m) {
          gaiku = m[2];
          narrowed_allocation = narrowed_allocation[gaiku];
          banchi_under = m[3];
        } else if (narrowed_allocation['']) {
          gaiku = '';
          narrowed_allocation = narrowed_allocation[gaiku];
          banchi_under = gaiku_under;
        } else {
          alert('The Gaiku that corresponds to the allocation-data could not be found. gaiku :' + gaiku_under);
        }
        if (banchi_under !== null) {
          r = RegExp("" + ("^(-|－)*(" + (((function() {
            var _results;
            _results = [];
            for (number in narrowed_allocation) {
              _ = narrowed_allocation[number];
              if (number !== '') {
                _results.push(number);
              }
            }
            return _results;
          })()).sort(function(a, b) {
            return b - a;
          }).join('|')) + ")(.*)$"));
          m = r.exec(banchi_under);
          if (m) {
            banchi = m[2];
            list = ["1." + address + " _ " + aza + "/" + gaiku + "/" + banchi + " _ " + narrowed_allocation[banchi]];
          } else {
            moreThan = checkMoreThan(banchi_under, narrowed_allocation);
            if (moreThan !== null) {
              list = ["4." + address + " _ " + aza + "/" + gaiku + "/" + moreThan[0] + " _ " + narrowed_allocation[moreThan[1]]];
            } else if (narrowed_allocation['']) {
              banchi = '';
              list = ["2." + address + " _ " + aza + "/" + gaiku + "/ _ " + narrowed_allocation['']];
            } else {
              alert('The Banchi corresponds to the allocation-data could not be found. banchi :' + banchi_under);
              bu = {};
              _ref = ((function() {
                var _results;
                _results = [];
                for (banchi in narrowed_allocation) {
                  chiku = narrowed_allocation[banchi];
                  _results.push(banchi.toOneByteAlphaNumeric());
                }
                return _results;
              })()).sort(function(a, b) {
                return a - b;
              });
              for (_i = 0, _len = _ref.length; _i < _len; _i++) {
                banchi = _ref[_i];
                if (!bu[narrowed_allocation[banchi]]) {
                  bu[narrowed_allocation[banchi]] = [banchi];
                } else {
                  bu[narrowed_allocation[banchi]].push(banchi);
                }
              }
              list = (function() {
                var _results;
                _results = [];
                for (chiku in bu) {
                  banchis = bu[chiku];
                  _results.push("3." + address + " _ " + aza + "/" + gaiku + "/" + (integrateNumbers(banchis).join(',')) + " _ " + chiku);
                }
                return _results;
              })();
            }
          }
        } else {
          alert('The Banchi could not be found in address.');
        }
      } else {
        alert('The Aza that corresponds to the allocation-data could not be found. aza :' + aza_under);
      }
    } else {
      alert('Not in Kanazawa. address :' + address);
    }
    return callback(list);
  };

  this.successReverseGeocode = function(result) {
    var address;
    address = result['Feature'][0]['Property']['Address'];
    return getAllocationData.call(this, address, function(chiku_list) {
      var chiku, _i, _len, _results;
      _results = [];
      for (_i = 0, _len = chiku_list.length; _i < _len; _i++) {
        chiku = chiku_list[_i];
        _results.push(document.body.innerHTML += '*&nbsp;' + chiku + '<br/>');
      }
      return _results;
    });
  };

  self = null;

  Mapview = (function() {
    function Mapview() {
      this.geocoder = null;
      this.map = null;
      this.infowindow = new google.maps.InfoWindow();
      this.marker = null;
    }

    Mapview.prototype.init = function() {
      var latlon, opts;
      self = this;
      this.geocoder = new google.maps.Geocoder();
      latlon = new google.maps.LatLng(sample_lat, sample_lon);
      opts = {
        zoom: self.zoomLevel = 18,
        mapTypeId: google.maps.MapTypeId.ROADMAP,
        center: latlon
      };
      this.map = new google.maps.Map(document.getElementById("map"), opts);
      google.maps.event.addListener(this.map, 'zoom_changed', function() {
        return self.zoomLevel = self.map.getZoom();
      });
      return google.maps.event.addListener(this.map, 'click', this.codeLatLng);
    };

    Mapview.prototype.codeLatLng = function(event) {
      var lat, latlon, lon;
      lat = event.latLng.lat();
      lon = event.latLng.lng();
      latlon = new google.maps.LatLng(lat, lon);
      return reverseGeoCode.call(self, lat, lon, 10, function(result) {
        console.log(result);
        return getAllocationData.call(self, result['Feature'][0]['Property']['Address'], function(chiku_list) {
          var chiku;
          self.marker = new google.maps.Marker({
            position: latlon,
            map: self.map
          });
          self.infowindow.setContent(window['Templates']['infowindow'].render({
            content: (function() {
              var _i, _len, _results;
              _results = [];
              for (_i = 0, _len = chiku_list.length; _i < _len; _i++) {
                chiku = chiku_list[_i];
                _results.push({
                  item: chiku
                });
              }
              return _results;
            })()
          }));
          return self.infowindow.open(self.map, self.marker);
        });
      });
    };

    return Mapview;

  })();

  $(function() {
    loadlib("./template.js");
    return new Mapview().init();
  });

}).call(this);
