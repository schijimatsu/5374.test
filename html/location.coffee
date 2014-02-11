"use strict"

YOLP = 'http://reverse.search.olp.yahooapis.jp/OpenLocalPlatform/V1/reverseGeoCoder'
APPID = 'dj0zaiZpPWowM3hJMjNhNEVhSSZzPWNvbnN1bWVyc2VjcmV0Jng9ODM-'
sample_lat = 36.55918528912932
sample_lon = 136.6466188430786
sample_json = "{\"ResultInfo\":{\"Count\":1,\"Total\":1,\"Start\":1,\"Latency\":0.0035960674285889,\"Status\":200,\"Description\":\"指定の地点の住所情報を取得する機能を提供します。\",\"Copyright\":\"Copyright (C) 2014 Yahoo Japan Corporation. All Rights Reserved.\",\"CompressType\":\"\"},\"Feature\":[{\"Property\":{\"Country\":{\"Code\":\"JP\",\"Name\":\"日本\"},\"Address\":\"石川県金沢市菊川２丁目１３\",\"AddressElement\":[{\"Name\":\"石川県\",\"Kana\":\"いしかわけん\",\"Level\":\"prefecture\",\"Code\":\"17\"},{\"Name\":\"金沢市\",\"Kana\":\"かなざわし\",\"Level\":\"city\",\"Code\":\"17201\"},{\"Name\":\"菊川\",\"Kana\":\"きくがわ\",\"Level\":\"oaza\"},{\"Name\":\"２丁目\",\"Kana\":\"２ちょうめ\",\"Level\":\"aza\"},{\"Name\":\"１３\",\"Kana\":\"１３\",\"Level\":\"detail1\"}],\"Building\":[{\"Id\":\"B@llF_pR1sI\",\"Name\":\"\",\"Floor\":\"2\",\"Area\":\"\"}]},\"Geometry\":{\"Type\":\"point\",\"Coordinates\":\"136.65982335805893,36.552413515466455\"}}]}"

String.prototype.toOneByteAlphaNumeric = ->
  return @replace /[Ａ-Ｚａ-ｚ０-９]/g, (s) ->
    return String.fromCharCode s.charCodeAt(0) - 0xFEE0

loadlib = (path) ->
  script = document.createElement 'script'
  script.setAttribute 'type', 'text/javascript'
  script.setAttribute 'src', path
  document.head.appendChild script

jsonp = (url, data, callback) ->
  console.log "calling jsonp."
  $.ajax {
    type: 'GET',
    url: url,
    dataType: 'jsonp', 
    data: (["#{k}=#{v}"] for k, v of data).join('&'), 
    success: callback, 
  }

getLocation = (success, fail) ->
  navigator.geolocation.getCurrentPosition success, fail, {
    enableHighAccuracy: true, 
    timeout: 5000, 
  }

successGetLocation = (position) ->
  console.log "lat: #{position.coords.latitude}, lon: #{position.coords.longitude}, accuracy: #{position.coords.accuracy}"
  reverseGeoCode position.coords.latitude, position.coords.longitude, position.coords.accuracy

failGetLocation = (error) ->
  console.log 'Error.'
  console.log error.message

reverseGeoCode = (lat, lon, accuracy, callback=null) ->
  callback = callback || successReverseGeocode
  console.log callback
  jsonp YOLP, {
    appid: APPID, 
    lat: lat, 
    lon: lon, 
    output: 'json', 
    datum: 'wgs', 
    callback: 'successReverseGeocode', 
    # dist: Math.floor(accuracy*1000)/1000, 
  }, callback

getAllocationData = (address, callback) ->
  if not @allocation
    # $.ajax {
    #   url: './allocation.json', 
    #   success: (data) ->
    #     console.log data
    #   , 
    #   error: (request, status, thrown) ->
    #     console.log request
    #     # console.log status
    #     console.log thrown
    # }
    $.getJSON './allocation.json', (data) ->
      @allocation = data
      getChikuList.call @, address, callback
  else
    getChikuList.call @, address, callback

getChikuList = (address, callback) ->
  list = {}
  m = ///^石川県金沢市(.*)$///.exec address
  if m
    aza_under = m[1]
    m = ///#{"^(#{(name for name, _ of @allocation).join('|')})(.*)$"}///.exec aza_under
    if m
      narrowed_allocation = @allocation[m[1]]
      gaiku_under = m[2]
      r = ///#{"^-*(#{(number for number, _ of narrowed_allocation if number != '').sort((a, b) ->
        return b - a
      ).join('|')})(.*)$"}///
      m = r.exec gaiku_under.toOneByteAlphaNumeric()
      if m
        narrowed_allocation = narrowed_allocation[m[1]]
        banchi_under = m[2]
      else if narrowed_allocation['']
        narrowed_allocation = narrowed_allocation['']
        banchi_under = gaiku_under
      else
        alert 'The Gaiku that corresponds to the allocation-data could not be found. gaiku :'+gaiku_under
        
      if banchi_under != null
        m = r.exec banchi_under
        if m
          list = [narrowed_allocation[m[1]]]
        else if narrowed_allocation['']
          list = [narrowed_allocation['']]
        else
          alert 'The Banchi corresponds to the allocation-data could not be found. banchi :'+banchi_under
          # list = ("#{banchi} : #{narrowed_allocation[banchi]}" for banchi in (banchi.toOneByteAlphaNumeric() for banchi, chiku of narrowed_allocation).sort((a, b) ->
          list = ("#{narrowed_allocation[banchi]}" for banchi in (banchi.toOneByteAlphaNumeric() for banchi, chiku of narrowed_allocation).sort((a, b) ->
            return a - b
          ))
    else
      alert 'The Aza that corresponds to the allocation-data could not be found. aza :'+aza_under
  else
    alert 'Not in Kanazawa. address :'+address

  callback list

@successReverseGeocode = (result) ->
  # document.body.innerHTML = JSON.stringify result
  address = result['Feature'][0]['Property']['Address']
  getAllocationData.call @, address, (chiku_list) ->
    for chiku in chiku_list
      document.body.innerHTML += '*&nbsp;'+chiku+'<br/>'

self = null
class Mapview

  constructor: () ->
    @geocoder = null
    @map = null
    @infowindow = new google.maps.InfoWindow()
    @marker = null

   # 初期化。bodyのonloadでinit()を指定することで呼び出してます
  init: () ->
    # Google Mapで利用する初期設定用の変数
    @geocoder = new google.maps.Geocoder();
    latlon = new google.maps.LatLng(sample_lat, sample_lon)
    opts = {
      zoom: 18, 
      mapTypeId: google.maps.MapTypeId.ROADMAP, 
      center: latlon, 
    }

    # getElementById("map")の"map"は、body内の<div id="map">より
    @map = new google.maps.Map(document.getElementById("map"), opts)

    google.maps.event.addListener(@map, 'click', @codeLatLng)
    self = @

  codeLatLng: (event) ->
    # input = document.getElementById('latlng').value;
    # var latlngStr = input.split(',', 2);
    lat = event.latLng.lat()
    lon = event.latLng.lng()
    latlon = new google.maps.LatLng lat, lon
    reverseGeoCode.call self, lat, lon, 10, (result) ->
      console.log result
      getAllocationData.call self, result['Feature'][0]['Property']['Address'], (chiku_list) ->
        self.map.setZoom 18
        self.marker = new google.maps.Marker {
          position: latlon, 
          map: self.map, 
        }
        self.infowindow.setContent (chiku for chiku in chiku_list).join('<br/>')
        self.infowindow.open self.map, self.marker

    # self.geocoder.geocode {'latLng': latlon}, (results, status) ->
    #   if status == google.maps.GeocoderStatus.OK
    #     if results[0]
    #       self.map.setZoom 16
    #       self.marker = new google.maps.Marker {
    #         position: latlon, 
    #         map: self.map, 
    #       }
    #       self.infowindow.setContent results[0].formatted_address
    #       self.infowindow.open self.map, self.marker
    #     else
    #       alert 'No results found'
    #   else
    #     alert 'Geocoder failed due to: ' + status

$(() ->
  new Mapview().init()
)
