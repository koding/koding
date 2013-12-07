# Kontrol is a class for communicating with the Kontrol Kite.
# In our application, there is only one instance of this and it can be
# reachable from KD.getSingleton("kontrol").
class Kontrol extends KDObject

  constructor: (options={})->
    super options

    kite =
      name     : "kontrol"
      publicIP : "#{KD.config.newkontrol.host}"
      port     : "#{KD.config.newkontrol.port}"

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
    query = @_sanitizeQuery query

    @kite.tell "getKites", [query], (res)=>
      err = res.withArgs[0]
      kites = res.withArgs[1]
      return callback err, null  if err

      kiteInstances = []
      for k in kites
        kiteInstances.push @_createKite k

      callback null, kiteInstances


  # watchKites watches for Kites that matches the query. The onEvent functions
  # is called for current kites and every new kite event.
  watchKites: (query={}, callback)->
    return warn "callback is not defined "  unless callback

    query = @_sanitizeQuery query

    onEvent = (e)=>
      log "kite event: ", e.action, {e}
      callback e.action, @_createKite {kite: e.kite, token: e.token}

    args = [query, onEvent]

    @kite.tell "getKites", args, (res)=>
      err = res.withArgs[0]
      kites = res.withArgs[1]
      return callback err, null  if err

      for k in kites
        e =
          action : @KiteAction.Register
          kite   : k
          token  : k.authentication.key

        callback e.action, @_createKite {kite: e.kite, token: e.token}

  # Returns a new NewKite instance from Kite data structure coming from
  # getKites() and watchKites() methods.
  _createKite: (k)->
    return new NewKite k.kite, {type: "token", key: k.token}

  _sanitizeQuery: (query) ->
    query.username    = "#{KD.nick()}"  unless query.username
    query.environment = "production"    unless query.environment

    return query

  KiteAction :
    Register   : "REGISTER"
    Deregister : "DEREGISTER"