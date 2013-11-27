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

  # Calls the callback function with the list of NewKite instances.
  # The returned kites are not connected. You must connect with NewKite.connect().
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
  getKites: (query={}, onKites, onError, onEvent)->
    if not query.username
      query.username = "#{KD.nick()}"
    if not query.environment
      query.environment = "production"

    eventCB = (e)=>
      log "kite event: ", {e}
      if onEvent
        onEvent e.action, @_createKite e.kite

    @kite.tell "getKites", [query, eventCB], (err, kites)=>
      log "getKites result: ", {err}, {kites}
      if err
        onError err
      else
        onKites (@_createKite k for k in kites)

  # Returns a new NewKite instance from Kite data structure coming from
  # getKites() and watchKites() methods.
  _createKite: (k)->
    return new NewKite k.kite, {type: "token", key: k.token}
