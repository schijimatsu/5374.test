"use strict"

YOLP = 'http://reverse.search.olp.yahooapis.jp/OpenLocalPlatform/V1/reverseGeoCoder'
APPID = 'dj0zaiZpPWowM3hJMjNhNEVhSSZzPWNvbnN1bWVyc2VjcmV0Jng9ODM-'
sample_lat = 36.55918528912932
sample_lon = 136.6466188430786
sample_json = "{\"ResultInfo\":{\"Count\":1,\"Total\":1,\"Start\":1,\"Latency\":0.0035960674285889,\"Status\":200,\"Description\":\"指定の地点の住所情報を取得する機能を提供します。\",\"Copyright\":\"Copyright (C) 2014 Yahoo Japan Corporation. All Rights Reserved.\",\"CompressType\":\"\"},\"Feature\":[{\"Property\":{\"Country\":{\"Code\":\"JP\",\"Name\":\"日本\"},\"Address\":\"石川県金沢市菊川２丁目１３\",\"AddressElement\":[{\"Name\":\"石川県\",\"Kana\":\"いしかわけん\",\"Level\":\"prefecture\",\"Code\":\"17\"},{\"Name\":\"金沢市\",\"Kana\":\"かなざわし\",\"Level\":\"city\",\"Code\":\"17201\"},{\"Name\":\"菊川\",\"Kana\":\"きくがわ\",\"Level\":\"oaza\"},{\"Name\":\"２丁目\",\"Kana\":\"２ちょうめ\",\"Level\":\"aza\"},{\"Name\":\"１３\",\"Kana\":\"１３\",\"Level\":\"detail1\"}],\"Building\":[{\"Id\":\"B@llF_pR1sI\",\"Name\":\"\",\"Floor\":\"2\",\"Area\":\"\"}]},\"Geometry\":{\"Type\":\"point\",\"Coordinates\":\"136.65982335805893,36.552413515466455\"}}]}"

String.prototype.toOneByteAlphaNumeric = ->
  return @replace /[Ａ-Ｚａ-ｚ０-９]/g, (s) ->
    return String.fromCharCode s.charCodeAt(0) - 0xFEE0

integrateNumbers = (numbers=[]) ->
  temp = []
  ret = []
  for number in numbers.sort((a, b) -> return a - b)
    number -= 0
    if temp.length == 0 or temp.slice(-1)[0]+1 == number
      temp.push number
    else
      ret.push broadOrSingle temp
      temp = [number]
  
  ret.push broadOrSingle temp
  return ret

broadOrSingle = (list) ->
  if list.length > 1
    return "#{list[0]}〜#{list.slice(-1)[0]}"
  else
    return list[0]

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

checkMoreThan = (banchi_under, narrowed_allocation) ->
  r = ///^([^0-9]*?)([0-9]+?)〜$///
  prefix = null
  value = null
  for k, v of narrowed_allocation
    m = r.exec k
    if m
      prefix = m[1]
      value = m[2]
      break

  if (value != null) and (banchi_under != '')
    r = ///^(-|－)?([^0-9]*?)([0-9]+)$///
    m = r.exec banchi_under
    if m and (m[3]-0) >= (value.toOneByteAlphaNumeric()-0)
      if prefix != null and prefix == m[2]
        return [m[3], prefix+value+'〜']
      else
        return [m[3], value+'〜']
    else
      return null
  else
    return null

getChikuList = (address, callback) ->
  list = {}
  m = ///^石川県金沢市(.*)$///.exec address
  if m
    aza_under = m[1]
    m = ///#{"^(#{(name for name, _ of @allocation).join('|')})(.*)$"}///.exec aza_under
    if m
      aza = m[1]
      narrowed_allocation = @allocation[aza]
      gaiku_under = m[2]
      r = ///#{"^(-|－)*(#{(number for number, _ of narrowed_allocation when number != '').sort((a, b) ->
        return b - a
      ).join('|')})(.*)$"}///
      m = r.exec gaiku_under.toOneByteAlphaNumeric()
      if m
        gaiku = m[2]
        narrowed_allocation = narrowed_allocation[gaiku]
        banchi_under = m[3]
      else if narrowed_allocation['']
        gaiku = ''
        narrowed_allocation = narrowed_allocation[gaiku]
        banchi_under = gaiku_under
      else
        alert 'The Gaiku that corresponds to the allocation-data could not be found. gaiku :'+gaiku_under
        
      if banchi_under != null
        r = ///#{"^(-|－)*(#{(number for number, _ of narrowed_allocation when number != '').sort((a, b) -> return b - a).join('|')})(.*)$"}///
        m = r.exec banchi_under
        if m
          banchi = m[2]
          list = ["1.#{address} _ #{aza}/#{gaiku}/#{banchi} _ #{narrowed_allocation[banchi]}"]
        else
          moreThan = checkMoreThan(banchi_under, narrowed_allocation)
          if moreThan != null
            list = ["4.#{address} _ #{aza}/#{gaiku}/#{moreThan[0]} _ #{narrowed_allocation[moreThan[1]]}"]
          else if narrowed_allocation['']
            banchi = ''
            list = ["2.#{address} _ #{aza}/#{gaiku}/ _ #{narrowed_allocation['']}"]
          else
            alert 'The Banchi corresponds to the allocation-data could not be found. banchi :'+banchi_under
            bu = {}
            for banchi in (banchi.toOneByteAlphaNumeric() for banchi, chiku of narrowed_allocation).sort((a, b) -> return a - b)
              if not bu[narrowed_allocation[banchi]]
                bu[narrowed_allocation[banchi]] = [banchi]
              else
                bu[narrowed_allocation[banchi]].push banchi
        
            list = ("3.#{address} _ #{aza}/#{gaiku}/#{integrateNumbers(banchis).join ','} _ #{chiku}" for chiku, banchis of bu)
      else
        alert 'The Banchi could not be found in address.'
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
    self = @
    @geocoder = new google.maps.Geocoder();
    latlon = new google.maps.LatLng(sample_lat, sample_lon)
    opts = {
      zoom: self.zoomLevel = 18, 
      mapTypeId: google.maps.MapTypeId.ROADMAP, 
      center: latlon, 
    }

    # getElementById("map")の"map"は、body内の<div id="map">より
    @map = new google.maps.Map(document.getElementById("map"), opts)

    google.maps.event.addListener @map, 'zoom_changed', ->
      self.zoomLevel = self.map.getZoom()

    google.maps.event.addListener @map, 'click', @codeLatLng

  codeLatLng: (event) ->
    # input = document.getElementById('latlng').value;
    # var latlngStr = input.split(',', 2);
    lat = event.latLng.lat()
    lon = event.latLng.lng()
    latlon = new google.maps.LatLng lat, lon
    reverseGeoCode.call self, lat, lon, 10, (result) ->
      console.log result
      getAllocationData.call self, result['Feature'][0]['Property']['Address'], (chiku_list) ->
        # self.map.setZoom self.zoomLevel
        self.marker = new google.maps.Marker {
          position: latlon, 
          map: self.map, 
        }
        # self.infowindow.setContent (chiku for chiku in chiku_list).join '<br/>'
        self.infowindow.setContent window['Templates']['infowindow'].render {
          content: ({item: chiku} for chiku in chiku_list)
        }
        # contains = $("div:contains('県')")
        # $(contains.get contains.length-1).parent().parent().find("div:first > :eq(3)").css {
        #   width: '500px', 
        # }
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
  loadlib "./template.js"
  new Mapview().init()
)
