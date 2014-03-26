class KodingKontrol extends (require 'kontrol')

  constructor: ->
    super
      url     : KD.config.newkontrol.url
      auth    :
        type  : 'sessionID'
        key   : Cookies.get 'clientId'

  fetchKites: (query = {}, callback) ->
    super (injectQueryParams query), callback

  injectQueryParams = (query) ->
    query.username = 'koding'
    query.environment = KD.config.environment
    query
