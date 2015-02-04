class GoogleApiClient extends KDObject

  @_e = {}


  @on = (eventName, listener) ->

    unless 'function' is typeof listener
      throw new Error 'listener is not a function'

    switch eventName
      when 'ready'
        return listener()  if @readyState

    super eventName, listener


  @loadDriveApi = (callback) ->

    gapi.client.load 'drive', 'v2', =>
      gapi.load 'auth:client,drive-realtime,drive-share', =>
        @authorizeDriveClient callback


  @authorizeDriveClient = do (interval = null) -> return (callback) ->

    url = '/-/google-api/authorize/drive'
    dataType = 'JSON'

    success = (token) =>

      gapi.auth.setToken token

      unless interval
        interval = KD.utils.repeat 60 * 55 * 1000, =>
          @authorizeDriveClient()

      callback()

    error = noop

    $.ajax {url, dataType, success, error}


  do ->

    window.handleGoogleApiLoaded = ->
      GoogleApiClient.readyState = yes
      GoogleApiClient.emit 'ready'

    identifier = 'google-api-client'
    url = 'https://apis.google.com/js/client.js?onload=handleGoogleApiLoaded'
    KodingAppsController.appendHeadElement 'script', {identifier, url}
