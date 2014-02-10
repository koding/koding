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
      e = options.withArgs[0]
      kite =
        kite   : e.kite
        token  :
          key  : e.token?.key
          ttl  : e.token?.ttl

      callback null, {action: e.action, kite: @_createKite kite}

    @kite.tell "getKites", [query, onEvent], (err, kites)=>
      return callback err, null  if err

      for kite in kites
        callback null, {action: @KiteAction.Register, kite: @_createKite kite}

  # Returns a new NewKite instance from Kite data structure coming from
  # getKites() and watchKites() methods.
  _createKite: (k)->
    new NewKite k.kite, {type: "token", key: k.token.key}

  _sanitizeQuery: (query) ->
    query.username    = "#{KD.nick()}"              unless query.username
    query.environment = "#{KD.config.environment}"  unless query.environment

  KiteAction :
    Register   : "REGISTER"
    Deregister : "DEREGISTER"
