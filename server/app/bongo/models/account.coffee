class JAccount extends Followable
  log4js          = require "log4js"
  log             = log4js.getLogger("[JAccount]")
    
  @mixin Filterable       # brings only static methods
  @::mixin Taggable::

  {secure,race} = bongo
  @share()
  Experience = 
    company           : String
    website           : String
    position          : String
    type              : String
    fromDate          : String
    toDate            : String
    description       : String
    # endorsements      : [
    #       endorser    : String
    #       title       : String
    #       text        : String
    #     ]
  @set
    tagRole             : 'skill'
    taggedContentRole   : 'developer'
    indexes:
      'profile.nickname' : 'unique'
    sharedMethods :
      static      : [
        'one', 'some', 'someWithRelationship'
        'someData', 'getAutoCompleteData', 'count'
        'byRelevance'
      ]
      instance    : [
        'on','update','follow','unfollow','fetchFollowersWithRelationship'
        'fetchFollowingWithRelationship','getDefaultEnvironment'
        'fetchMounts','fetchActivityTeasers','fetchRepos','fetchDatabases'
        'fetchMail','fetchNotificationsTimeline','fetchActivities'
        'fetchStorage','count','addTags','tellKite','fetchLimit','fetchKiteIds'
        'fetchFollowedTopics', 'tellKite2','fetchKiteChannelId'
        'fetchNonces'
      ]
    schema                  :
      skillTags             : [String]
      locationTags          : [String]
      systemInfo            :
        # defaultEnvironment  : JEnvironment
        defaultToLastUsedEnvironment :
          type              : Boolean
          default           : yes
      counts                : Followable.schema.counts
      environmentIsCreated  : Boolean
      profile               :
        about               : 
          type              : String
          default           : "I'm still trying to find my way in the world..."
        nickname            :
          type              : String
          validate          : (value)->
            3 < value.length < 26 and /^[^-][a-z0-9-]+$/.test value
          set               : (value)-> value.toLowerCase()
        hash                :
          type              : String
          # email             : yes
        ircNickname         : String
        firstName           :
          type              : String
          required          : yes
        lastName            : 
          type              : String
          default           : ''
        description         : String
        avatar              : String
        status              : String
        experience          : String
        experiencePoints    :
          type              : Number
          default           : 0
        lastStatusUpdate    : String
      meta                  : require 'bongo/bundles/meta'
    relationships           : ->
      environment   :
        as          : 'owner'
        targetType  : JEnvironment

      mount         :
        as          : 'owner'
        targetType  : JMount

      repo          :
        as          : 'owner'
        targetType  : JRepo

      database      :
        as          : 'owner'
        targetType  : JDatabase

      follower      :
        as          : 'follower'
        targetType  : JAccount

      # followee      :
      #   as          : 'followee'
      #   targetType  : JAccount
      
      activity      :
        as          : ['author','commenter','repliesActivity']
        targetType  : CActivity
      
      privateMessage:
        as          : ['recipient','sender']
        targetType  : JPrivateMessage

      appStorage    :
        as          : 'appStorage'
        targetType  : JAppStorage
      
      limit:
        as          : ['invite']
        targetType  : JLimit
      
      tag:
        as          : 'skill'
        targetType  : JTag

  # bongo.on 'clientDidDisconnect', (connection)->
  #   if connection?.delegate instanceof JAccount
  #     {remoteId, delegate} = connection
  #     delegate.tellKite2 {connection}, null,
  #       kiteId    : '*'
  #       toDo      : '_disconnect'
  #     , ->
  
  @findSuggestions = (seed, options, callback)->
    {limit,blacklist}  = options

    @some {
      $or : [
          ( 'profile.nickname'  : seed )
          ( 'profile.firstName' : seed )
          ( 'profile.lastName'  : seed )
        ],
      _id     : 
        $nin  : blacklist
    },{
      limit
      sort    : 'profile.firstName' : 1
    }, callback

  @getAutoCompleteData = (fieldString, queryString, callback)->
    query = {}
    desiredData = {}
    query[fieldString] = RegExp queryString, 'i'
    desiredData[fieldString] = yes
    @someData query, desiredData, (err, cursor)->
      cursor.toArray (err, docs)->
        results = []
        for doc in docs
          results.push doc.profile.fullname
        callback err, results

  constructor:(options)->
    super options
    @kites = {}
  
  # fetchNonce: bongo.secure (client, callback)->
  #   {delegate} = client.connection
  #   unless @equals delegate
  #     callback new KodingError 'Access denied.'
  #   else
  #     client.connection.remote.fetchClientId (clientId)->
  #       JSession.one {clientId}, (err, session)->
  #         if err
  #           callback err
  #         else
  #           nonce = hat()
  #           session.update $set: {nonce}, (err)->
  #             if err
  #               callback err
  #             else
  #               callback null, nonce
  
  fetchNonces: bongo.secure (client, callback)->
    {delegate} = client.connection
    unless @equals delegate
      callback new KodingError 'Access denied.'
    else
      client.connection.remote.fetchClientId (clientId)->
        JSession.one {clientId}, (err, session)->
          if err
            callback err
          else
            nonces = (hat() for i in [0...10])
            session.update $addToSet: nonces: $each: nonces, (err)->
              if err
                callback err
              else
                callback null, nonces

  answerToLifeTheUniverseAndEverything:(callback)-> callback 42
  
  fetchKiteIds: bongo.secure ({connection}, options, callback)->
    {kiteName} = options
    {hostname} = kiteConfig.kites[kiteName]
    if kiteName in ["sharedHosting","terminaljs","fsWatcher"]
      kiteController.query {kiteName, hostname}, (err,kiteIds)=>
        log.debug "got the kites",{kiteIds}
        if err then console.dir err else
          callback? null,kiteIds
    else
      kiteController.query {kiteName}, (err,kiteIds)=>
        if err then console.dir err else
          callback? null,kiteIds
  
  fetchKiteChannelId: bongo.secure (client, kiteName, callback)->
    {delegate} = client.connection
    unless delegate instanceof JAccount
      callback new KodingError 'Access denied.'
    else
      callback null, "private-#{kiteName}-#{delegate.profile.nickname}"
  
  tellKite2: bongo.secure bongo.useMQ (client, channelId, args, callback)->
    {delegate} = client.connection
    {kiteId, toDo} = args
    unless delegate instanceof JAccount
      return callback new KodingError 'Access denied'
    secretChannelId = channelId #+ delegate.profile.nickname
    JChannel.one {secretChannelId}, (err, channel)->
      if err
        callback err
      else if channel?
        callback new KodingError 'Unavailable channel id'
      else
        delegateId = delegate.getId()
        channel = new JChannel {
          publicChannelId: delegateId + kiteId + Date.now() + '_private'
          secretChannelId
          subscribers: unless args.toDo in ['_disconnect', '_connect']
            [kiteId, delegateId].filter (item)-> item?
        }
        channel.save (err)->
          if err then callback err
          else
            args.secretChannelId  = secretChannelId
            args.callbackId       = callback.id
            args.requesterId      = client.connection.remoteId
            args.subscriberCount  = channel.getAt('subscribers')?.length or 0
            # uri = "http://localhost:1337/?data=#{
            uri = "https://api.koding.com/1.1/kite/sharedHosting?data=#{
              encodeURIComponent JSON.stringify args
            }"
            nodeRequest uri, (err, response, body)->
              if err then callback err
              else
                try response = JSON.parse body
                catch e then return callback new KodingError(
                  "Invalid response: #{body}"
                )
                if response?.error then callback new KodingError response.error
                else callback null, __channelId: secretChannelId
  
  tellKiteInternal : (account,options,callback)->
    {kiteId,kiteName,toDo,withArgs} = options
    
    if not account?.profile?.nickname
      # log.error "account.tellKite is called from another class, it can only be called from a browser"
      return callback? "you can only call account.tellKite from a browser."
        
    # {delegate} = connection
    {kiteName,kiteId,toDo,withArgs} = options
    
    # KITE SECURITY BACKBONE - NEVER REMOVE.
    withArgs ?= {}
    withArgs.username = account.profile.nickname
    # 
        
    completeTheRequest = ({kiteId,toDo,options},env,callback) =>
      kiteController.tell {kiteId, toDo, withArgs,callback},(err)=>
        # log.debug "unsetting the kite"
        if err
          newErr = {
            kiteMsg        : err
            kiteNotPresent : true
            kiteName
            kiteId
          }
          log.error err
          callback newErr
          env.unsetKite {kiteId},(err)->
            unless err
              # log.debug "kite is unset",env
              
            else
              # log.debug err
        
    unless @equals account
      err = "Guest can't access kites."
      log.error err
      callback new KodingError err
    else
      # # log.debug "getting the kite"
      @fetchEnvironment (err,env)=>
        # console.log "--sdf->",arguments       
        if err
          callback 'problem with db, try later.'
        else if env
          # log.debug "env is there", env
          if kiteId and kiteName
            env.setKite kiteName,kiteId,(err)=>
              unless err
                completeTheRequest {kiteId,toDo,withArgs},env,callback
              else
                callback "couldn't set the kite, please try again."
          
          else if kiteName
            env.getKiteId {kiteName,discover:yes,setKite:yes},(err,kiteId)->
              if err
                log.error err
                callback err
              else
                completeTheRequest {kiteId,toDo,withArgs},env,callback
          else
            callback "you must provide kiteName or kiteId"
        else
          # create env
          # # log.debug "create new env"
          env = new JEnvironment kites: {testKite:"1234"}
          # # log.debug env

          env.save (err)=>
            if err
              # # log.debug "couldn't save the env to db"
            else
              # # log.debug "we're cool"
              @addEnvironment env,(err)->
                unless err
                  env.getKiteId {kiteName,discover:yes,setKite:yes},(err,kiteId)->
                    if err
                      log.error err
                      callback err
                    else
                      completeTheRequest {kiteId,toDo,withArgs},env,callback
                else
                  callback err        
                  
  tellKite: bongo.secure ({connection}, options, callback)->

    #
    # USAGE :
    #
    # options =
    #   kiteName  : String      # sharedHosting
    #   toDo      : String      # createFile
    #   withArgs  : Array       # client provided data to be passed to the kite function
    #
    
    if not connection?.delegate?.profile?.nickname
      # log.error "account.tellKite is called from another class, it can only be called from a browser"
      return callback? "you can only call account.tellKite from a browser."
    else
      @tellKiteInternal @,options,callback

  addTags: secure (client, tagPath, tags, callback)->
    Taggable::addTags.call @, client, tags, (err)=>
      tagSet = {}
      tagSet[tagPath] = tags
      @update client, $set: tagSet, callback
  
  fetchMail:do ->
    collectParticipants = (messages, delegate, callback)->
      fetchParticipants = race (i, message, fin)->
        register = new Register # a register per message...
        jraphical.Relationship.all targetName: 'JPrivateMessage', targetId: message.getId(), sourceId: $ne: delegate.getId(), (err, rels)->
          if err
            callback err
          else
            message.participants = (rel for rel in rels when register.sign rel.sourceId) # only include unique participants.
            fin()
      , callback
      fetchParticipants(message) for message in messages when message?
    
    secure ({connection}, options, callback)->
      [callback, options] = [options, callback] unless callback
      unless @equals connection.delegate
        callback new Error 'Access denied.'
      else
        options or= {}
        selector = 
          if options.as
            as: options.as
          else
            {}
        @fetchPrivateMessages selector, options, (err, messages)->
          if err
            callback err
          else
            collectParticipants messages, connection.delegate, (err)->
              if err
                callback err
              else
                callback null, messages
  
  fetchNotificationsTimeline: bongo.secure ({connection}, selector, options, callback)->
    unless @equals connection.delegate
      callback new Error 'Access denied.'
    else
      @fetchActivities selector, options, @constructor.collectTeasersAllCallback callback
  
  fetchActivityTeasers : bongo.secure ({connection}, selector, options, callback)->
    unless @equals connection.delegate
      callback new Error 'Access denied.'
    else
      @fetchActivities selector, options, @constructor.collectTeasersAllCallback (err, items)->
        if err
          callback err
        else
          items = for item in items
            uniqueSourceOrigins = {}
            for relationship in item \
              when not uniqueSourceOrigins[targetOriginId = relationship.target.originId]? and
                   not targetOriginId.equals connection.delegate.getId()
              uniqueSourceOrigins[targetOriginId] = yes
              sourceOriginId = relationship.source.originId
              sourceOriginName = relationship.source.originType
              targetOriginName = relationship.target.originType
              {sourceId, targetId, sourceName, targetName, as, timestamp} = relationship
              {
                sourceOriginName
                sourceOriginId
                targetOriginName
                targetOriginId
                sourceName
                sourceId
                targetName
                targetId
                as
                timestamp
              }
          callback null, items.filter (item)-> item.length > 0

  update: bongo.secure (client, changes, callback) ->
    if client.connection.delegate.equals @
      jraphical.Module::update.call @, changes, callback

  oldFetchMounts = @::fetchMounts
  fetchMounts: bongo.secure (client,callback)->
    if @equals client.connection.delegate
      oldFetchMounts.call @,callback
    else
      callback new Error "access denied for guest."

  oldFetchRepos = @::fetchRepos  
  fetchRepos: bongo.secure (client,callback)->
    if @equals client.connection.delegate
      oldFetchRepos.call @,callback
    else
      callback new Error "access denied for guest."    

  oldFetchDatabases = @::fetchDatabases  
  fetchDatabases: bongo.secure (client,callback)->
    if @equals client.connection.delegate
      oldFetchDatabases.call @,callback
    else
      callback new Error "access denied for guest."    

  # 
  # getEnvironments:(callback)->
  #   
  #   callback
  # 
  # createDefaultEnvironment:(options,callback)->
  #   
  createEnvironment:(options,callback)->
    @fetchEnvironment "hosts.hostname":res.backend,(err,environment)=>
      if err then callback err
      else if environment
        callback null,environment
      else
        environment = {hosts:[hostname:res.backend,port:0]}
        environment.save (err)=>
          if err then callback err
          else
            @addEnvironment environment,(err)=>
              if err then callback err
              else
                callback null,environment    
  
  getDefaultEnvironment: bongo.secure (client, callback)->
    unless @equals client.connection.delegate
      return callback null, 'Not enough privileges'

    defaultEnvironment = new JEnvironment environmentId : 'wikiwikiblueblue'
    callback defaultEnvironment

  setClientId:(@clientId)->
  
  getFullName:->
    {profile} = @data
    profile.firstName+' '+profile.lastName
  
  fetchStorage: bongo.secure (client, options, callback)->
    account = @
    unless @equals client.connection.delegate
      return callback "Attempt to access unauthorized application storage"
    
    {appId, version} = options
    @fetchAppStorage {}, {targetOptions:query:{appId}}, (error, storage)->
      if error then callback error
      else
        unless storage?
          log.info 'creating new storage for application', appId, version
          newStorage = new JAppStorage {appId, version}
          newStorage.save (error) =>
            if error then callback error
            else
              account.addAppStorage newStorage, (err)->
                callback err, newStorage
        else
          callback error, storage
    
