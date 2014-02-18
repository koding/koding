# Kontrol is a class for communicating with the Kontrol Kite.
# In our application, there is only one instance of this and it can be
# reachable from KD.getSingleton("kontrol").
class Kontrol extends KDObject

  constructor: (options={})->
    super options

    kite =
      name     : "kontrol"
      url      : "#{KD.config.newkontrol.url}"

    authentication =
      type     : "sessionID"
      key      : KD.remote.getSessionToken()

    @kite = new NewKite kite, authentication
    @kite.connect()

  # getKites Calls the callback function with the list of NewKite instances.
  # The returned kites are not connected. You must connect with
  # NewKite.connect().
  #
  # Query parameters are below from general to specific:
  #
  #   username    string
  #   environment string
  #   name        string
  #   version     string
  #   region      string
  #   hostname    string
  #   id          string
  #
  getKites: (query={}, callback = noop)->
    @_sanitizeQuery query

    @kite.tell "getKites", [query], (err, kites)=>
      return callback err, null  if err

      callback null, (@_createKite k for k in kites)

  # watchKites watches for Kites that matches the query. The onEvent functions
  # is called for current kites and every new kite event.
  watchKites: (query={}, callback)->
    return warn "callback is not defined "  unless callback

    @_sanitizeQuery query

    onEvent = (options)=>
      err = options.withArgs[1]
      return callback err, null  if err

      e = options.withArgs[0]
      callback null, {action: e.action, kite: @_createKite e}

    @kite.tell "getKites", [query, onEvent], (err, result)=>
      return callback err, null  if err

      # Watcher ID is here but I don't know where to store it. (Cenk)
      # result.watcherID

      for kite in result.kites
        callback null, {action: @KiteAction.Register, kite: @_createKite kite}

  cancelWatcher: (id, callback)->
    @kite.tell "cancelWatcher", [id], (err, result)=>
      return callback err  # result will always be "null"

  # Returns a new NewKite instance from Kite data structure coming from
  # getKites() and watchKites() methods.
  _createKite: (k)->
    new NewKite k.kite, {type: "token", key: k.token}

  _sanitizeQuery: (query) ->
    query.username    = "#{KD.nick()}"              unless query.username
    query.environment = "#{KD.config.environment}"  unless query.environment

  KiteAction :
    Register   : "REGISTER"
    Deregister : "DEREGISTER"
