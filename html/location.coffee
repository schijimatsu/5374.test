"use strict"

YOLP = 'http://reverse.search.olp.yahooapis.jp/OpenLocalPlatform/V1/reverseGeoCoder'
APPID = 'dj0zaiZpPWowM3hJMjNhNEVhSSZzPWNvbnN1bWVyc2VjcmV0Jng9ODM-'

loadlib = (path) ->
  script = document.createElement 'script'
  script.setAttribute 'type', 'text/javascript'
  script.setAttribute 'src', path
  document.head.appendChild script

jsonp = (url, data, callback) ->
  path = [url, '?', ]
  path = Array.prototype.concat path, ["#{k}=#{v}", '&'] for k, v of data
  path = Array.prototype.concat path, "callback=#{callback}&output=json"
  console.log "calling jsonp. url: #{path.join ''}"
  loadlib path.join ''

getLocation = (success, fail) ->
  navigator.geolocation.getCurrentPosition success, fail, {
    enableHighAccuracy: true, 
    timeout: 5000
  }

successGetLocation = (position) ->
  console.log "lat: #{position.coords.latitude}, lon: #{position.coords.longitude}, accuracy: #{position.coords.accuracy}"
  reverseGeoCode position.coords.latitude, position.coords.longitude, position.coords.accuracy

failGetLocation = (error) ->
  console.log 'Error.'
  console.log error.message

reverseGeoCode = (lat, lon, accuracy) ->
  jsonp YOLP, {
    appid: APPID, 
    lat: lat, 
    lon: lon, 
    # dist: Math.floor(accuracy*1000)/1000, 
  }, 'successReverseGeocode'

@successReverseGeocode = (result) ->
  document.body.innerHTML = JSON.stringify result

$(() ->
  getLocation successGetLocation, failGetLocation
)
