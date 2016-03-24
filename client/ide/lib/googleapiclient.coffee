kd = require 'kd'
KDObject = kd.Object
KodingAppsController = require 'app/kodingappscontroller'
IDEMetrics = require './idemetrics'
$ = require 'jquery'

module.exports = class GoogleApiClient extends KDObject

  { noop } = kd
  @_e = {}


  @on = (eventName, listener) ->

    unless 'function' is typeof listener
      throw new Error 'listener is not a function'

    switch eventName
      when 'ready'
        return listener()  if @readyState

    super eventName, listener


  @loadDriveApi = (callback) ->

    @metric 'drive', 'load_request'
    gapi.client.load 'drive', 'v2', =>
      @metric 'drive', 'loaded'

      @metric 'drive-realtime', 'load_request'
      gapi.load 'auth:client,drive-realtime,drive-share', =>
        @metric 'drive-realtime', 'loaded'

        @authorizeDriveClient callback


  @authorizeDriveClient = do (interval = null) -> return (callback = noop) ->

    GoogleApiClient.metric 'drive', 'authorization_request'

    url = '/-/google-api/authorize/drive'
    dataType = 'JSON'

    success = (token) =>

      GoogleApiClient.metric 'drive', 'authorized'
      gapi.auth.setToken token

      unless interval
        interval = kd.utils.repeat 60 * 55 * 1000, =>
          @metric 'drive', 'reauthorization_request'
          @authorizeDriveClient()

      callback()

    error = noop

    $.ajax { url, dataType, success, error }


  @metric = (name, state, count = 1, callback = noop) ->

    name = if name
    then "google_api_client.#{name}"
    else 'google_api_client'

    IDEMetrics.collect name, state, count, callback


  do ->

    global.handleGoogleApiLoaded = ->
      GoogleApiClient.metric null, 'loaded'
      GoogleApiClient.readyState = yes
      GoogleApiClient.emit 'ready'

    return global.handleGoogleApiLoaded()  if global.gapi

    identifier = 'google-api-client'
    url = 'https://apis.google.com/js/client.js?onload=handleGoogleApiLoaded'
    KodingAppsController.appendHeadElement 'script', { identifier, url }

    GoogleApiClient.metric null, 'load_request'
