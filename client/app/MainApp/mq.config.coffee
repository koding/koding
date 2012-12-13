KD.remote = new Bongo

  getUserArea:-> KD.getSingleton('mainController').getUserArea()

  getSessionToken:-> $.cookie('clientId')

  createRoutingKey:(service, event)->
    "client.#{Bongo.createId()}.#{KD.whoami().profile.nickname}.#{service}.#{event}"

  fetchName:do->
    cache = {}
    (nameStr, callback)->
      if cache[nameStr]?
        {model, name} = cache[nameStr]
        return callback null, model, name
      @api.JName.one {name:nameStr}, (err, name)=>
        if err then return callback err
        else unless name?
          return callback new Error "Unknown name: #{nameStr}"
        else if name.constructorName is 'JUser'
          # SPECIAL CASE: map JUser over to JAccount...
          name = new @api.JName {
            name            : name.name
            constructorName : 'JAccount'
            usedAsPath      : 'profile.nickname'
          }
        selector = {}
        selector[name.usedAsPath] = name.name
        @api[name.constructorName].one? selector, (err, model)->
          if err then callback err
          else unless model?
            callback new Error(
              "Unable to find model: #{nameStr} of type #{name.constructorName}"
            )
          else
            cache[nameStr] = {model, name}
            callback null, model, name

  mq: do->
    {broker} = KD.config
    brokerOptions = {
      encrypted     : yes
      sockURL       : broker.sockJS
      authEndPoint  : broker.auth
      vhost         : broker.vhost
      autoReconnect : yes
    }
    broker = new Broker broker.apiKey, brokerOptions