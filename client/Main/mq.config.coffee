getSessionToken=-> Cookies.get 'clientId'

{ socialApiUri: apiEndpoint } = KD.config

KD.remote = new Bongo

  apiEndpoint: apiEndpoint

  resourceName: KD.config.resourceName ? 'koding-social'

  getUserArea:-> KD.getSingleton('groupsController').getUserArea()

  getSessionToken: getSessionToken

  apiDescriptor: REMOTE_API

  # createRoutingKey:(service, event)->
    # "client.#{Bongo.createId()}.#{KD.whoami().profile.nickname}.#{service}.#{event}"

  fetchName:do->
    cache = {}
    {dash} = Bongo
    (nameStr, callback)->
      if cache[nameStr]?
        {model, name} = cache[nameStr]
        return callback null, model, name
      @api.JName.one {name:nameStr}, (err, name)=>
        if err then return callback err
        else unless name?
          return callback new Error "Unknown name: #{nameStr}"
        else if name.slugs[0].constructorName is 'JUser'
          # SPECIAL CASE: map JUser over to JAccount...
          name = new @api.JName
            name              : name.name
            slugs             : [{
              constructorName : 'JAccount'
              collectionName  : 'jAccounts'
              slug            : name.name
              usedAsPath      : 'profile.nickname'
            }]
        models = []
        err = null
        queue = name.slugs.map (slug) => =>
          selector = {}
          selector[slug.usedAsPath] = slug.slug
          @api[slug.constructorName].one? selector, (err, model)->
            if err then callback err
            else
              unless model?
                err = new Error \
                  "Unable to find model: #{nameStr} of type #{name.constructorName}"
              else
                models.push model
              queue.fin()

        dash queue, =>
          @emit "modelsReady"
          callback err, models, name

  mq: do ->
    {authExchange} = KD.config
    # { servicesEndpoint } = KD.config.broker

    options = {
      # servicesEndpoint
      authExchange
      autoReconnect: yes
      getSessionToken
    }
    console.log "connecting to:"+KD.config.broker.uri
    broker = new KDBroker.Broker "#{KD.config.broker.uri}", options
