"use strict"

rtclient                   = rtclient or {}
window.rtclient            = rtclient
rtclient.INSTALL_SCOPE     = "https://www.googleapis.com/auth/drive.install"
rtclient.FILE_SCOPE        = "https://www.googleapis.com/auth/drive.file"
rtclient.OPENID_SCOPE      = "openid"
rtclient.REALTIME_MIMETYPE = "application/vnd.google-apps.drive-sdk"

rtclient.getParams = ->
  params = {}
  hashFragment = window.location.hash
  if hashFragment

    # split up the query string and store in an object
    paramStrs = hashFragment.slice(1).split("&")
    i = 0

    while i < paramStrs.length
      paramStr = paramStrs[i].split("=")
      params[paramStr[0]] = unescape(paramStr[1])
      i++
  console.log "-- params -->",params
  params


rtclient.params = rtclient.getParams()

rtclient.getOption = (options, key, defaultValue) ->
  value = (if not options[key]? then defaultValue else options[key])
  console.error key + " should be present in the options."  unless value?
  console.log "-- value -->", value
  return value


rtclient.Authorizer = (options) ->
  @clientId = rtclient.getOption(options, "clientId")

  # Get the user ID if it's available in the state query parameter.
  @userId = rtclient.params["userId"]
  @authButton = document.getElementById(rtclient.getOption(options, "authButtonElementId"))
  return null


rtclient.Authorizer::start = (onAuthComplete) ->
  gapi.load "auth:client,drive-realtime,drive-share", =>
    @authorize onAuthComplete



rtclient.Authorizer::authorize = (onAuthComplete) ->
  clientId = @clientId
  userId = @userId

  console.log "-- authorize @ onAuthComplete -->",onAuthComplete

  handleAuthResult = (authResult) =>

    console.log "-- auth result -->",authResult

    if authResult and not authResult.error
      @authButton.disabled = true
      @fetchUserId onAuthComplete
    else
      @authButton.disabled = false
      @authButton.onclick  = authorizeWithPopup


  authorizeWithPopup = ->
    gapi.auth.authorize
      client_id: clientId
      scope: [
        rtclient.INSTALL_SCOPE
        rtclient.FILE_SCOPE
        rtclient.OPENID_SCOPE
      ]
      user_id: userId
      immediate: false
    , handleAuthResult



  # Try with no popups first.
  gapi.auth.authorize
    client_id: clientId
    scope: [
      rtclient.INSTALL_SCOPE
      rtclient.FILE_SCOPE
      rtclient.OPENID_SCOPE
    ]
    user_id: userId
    immediate: true
  , handleAuthResult



rtclient.Authorizer::fetchUserId = (callback) ->

  gapi.client.load "oauth2", "v2", =>
    gapi.client.oauth2.userinfo.get().execute (resp) =>
      @userId = resp.id  if resp.id
      callback()  if callback

rtclient.createRealtimeFile = (title, mimeType, callback) ->
  gapi.client.load "drive", "v2", ->
    gapi.client.drive.files.insert(resource:
      mimeType: mimeType
      title: title
    ).execute callback



rtclient.getFileMetadata = (fileId, callback) ->
  gapi.client.load "drive", "v2", ->
    gapi.client.drive.files.get(fileId: fileId).execute callback



###*
Parses the state parameter passed from the Drive user interface after Open
With operations.
@param stateParam {Object} the state query parameter as an object or null if
parsing failed.
###
rtclient.parseState = (stateParam) ->
  try
    stateObj = JSON.parse(stateParam)
    return stateObj
  catch e
    return null



###*
Handles authorizing, parsing query parameters, loading and creating Realtime
documents.
@constructor
@param options {Object} options for loader. Four keys are required as mandatory, these are:

1. "clientId", the Client ID from the console
2. "initializeModel", the callback to call when the model is first created.
3. "onFileLoaded", the callback to call when the file is loaded.

and one key is optional:

1. "defaultTitle", the title of newly created Realtime files.
###
rtclient.RealtimeLoader = (options) ->

  # Initialize configuration variables.
  @onFileLoaded    = rtclient.getOption options, "onFileLoaded"
  @newFileMimeType = rtclient.getOption options, "newFileMimeType", rtclient.REALTIME_MIMETYPE
  @initializeModel = rtclient.getOption options, "initializeModel"
  @registerTypes   = rtclient.getOption options, "registerTypes", ->
  @afterAuth       = rtclient.getOption options, "afterAuth", ->
  @autoCreate      = rtclient.getOption options, "autoCreate", false # This tells us if need to we automatically create a file after auth
  @defaultTitle    = rtclient.getOption options, "defaultTitle", "New Realtime File"
  @authorizer      = new rtclient.Authorizer(options)
  return


###*
Redirects the browser back to the current page with an appropriate file ID.
@param fileIds {Array.} the IDs of the files to open.
@param userId {string} the ID of the user.
###
rtclient.RealtimeLoader::redirectTo = (fileIds, userId) ->
  params = []
  params.push "fileIds=" + fileIds.join(",")  if fileIds
  params.push "userId=" + userId  if userId

  # Naive URL construction.
  newUrl = (if params.length is 0 then "./" else ("./#" + params.join("&")))

  # Using HTML URL re-write if available.
  if window.history and window.history.replaceState
    window.history.replaceState "Google Drive Realtime API Playground", "Google Drive Realtime API Playground", newUrl
  else
    window.location.href = newUrl

  # We are still here that means the page didn't reload.
  rtclient.params = rtclient.getParams()
  for index of fileIds
    gapi.drive.realtime.load fileIds[index], @onFileLoaded, @initializeModel, @handleErrors
  return


###*
Starts the loader by authorizing.
###
rtclient.RealtimeLoader::start = ->

  # Bind to local context to make them suitable for callbacks.

  @authorizer.start =>
    @registerTypes()  if @registerTypes
    @afterAuth()  if @afterAuth
    @load()
    return

  return


###*
Handles errors thrown by the Realtime API.
###
rtclient.RealtimeLoader::handleErrors = (e) ->
  if e.type is gapi.drive.realtime.ErrorType.TOKEN_REFRESH_REQUIRED
    authorizer.authorize()
  else if e.type is gapi.drive.realtime.ErrorType.CLIENT_ERROR
    alert "An Error happened: " + e.message
    window.location.href = "/"
  else if e.type is gapi.drive.realtime.ErrorType.NOT_FOUND
    alert "The file was not found. It does not exist or you do not have read access to the file."
    window.location.href = "/"
  return


###*
Loads or creates a Realtime file depending on the fileId and state query
parameters.
###
rtclient.RealtimeLoader::load = ->
  fileIds = rtclient.params["fileIds"]
  fileIds = fileIds.split(",")  if fileIds
  userId = @authorizer.userId
  state = rtclient.params["state"]

  # Creating the error callback.
  authorizer = @authorizer

  # We have file IDs in the query parameters, so we will use them to load a file.
  if fileIds
    for index of fileIds
      gapi.drive.realtime.load fileIds[index], @onFileLoaded, @initializeModel, @handleErrors
    return

  # We have a state parameter being redirected from the Drive UI. We will parse
  # it and redirect to the fileId contained.
  else if state
    stateObj = rtclient.parseState(state)

    # If opening a file from Drive.
    if stateObj.action is "open"
      fileIds = stateObj.ids
      userId = stateObj.userId
      @redirectTo fileIds, userId
      return
  @createNewFileAndRedirect()  if @autoCreate
  return


###*
Creates a new file and redirects to the URL to load it.
###
rtclient.RealtimeLoader::createNewFileAndRedirect = ->

  # No fileId or state have been passed. We create a new Realtime file and
  # redirect to it.

  rtclient.createRealtimeFile @defaultTitle, @newFileMimeType, (file) =>
    if file.id
      @redirectTo [file.id], @authorizer.userId

    # File failed to be created, log why and do not attempt to redirect.
    else
      console.error "Error creating file."
      console.error file
    return

  return
