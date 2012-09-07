class JAppScriptAttachment extends jraphical.Attachment
  @setSchema
    as          : String
    description : String
    content     : String
    syntax      : String

class JApp extends jraphical.Module

  @mixin Filterable       # brings only static methods
  @mixin Followable       # brings only static methods
  @::mixin Followable::   # brings only prototype methods
  @::mixin Taggable::

  {Inflector,JsPath,secure,daisy} = bongo
  {Relationship} = jraphical

  {log} = console

  @getAuthorType =-> JAccount

  @share()

  @set
    emitFollowingActivities: yes
    indexes         :
      title         : 'ascending'

    sharedMethods   :
      instance      : [
        "update",'follow', 'unfollow', 'remove', 'like', 'fetchLikedByes', 'checkIfLikedBefore',
        'fetchFollowersWithRelationship', 'fetchFollowingWithRelationship', 'fetchCreator', 'install'
      ]
      static        : [
        "one","on","some","create"
        'someWithRelationship','byRelevance'
      ]

    schema          :
      title         :
        type        : String
        set         : (value)-> value.trim()
        required    : yes
      body          : String
      attachments   : [JAppScriptAttachment]
      counts        :
        followers   :
          type      : Number
          default   : 0
        installed   :
          type      : Number
          default   : 0
      thumbnails    : [Object]
      screenshots   : [Object]
      meta          : require "bongo/bundles/meta"
      manifest      : Object
      type          :
        type        : String
        enum        : ["Wrong type specified!",["web-app", "add-on", "server-stack", "framework"]]
        default     : "web-app"

    relationships   :
      creator       : JAccount
      review        :
        targetType  : jraphical.Module
        as          : 'review'
      activity      :
        targetType  : CActivity
        as          : 'activity'
      follower      :
        targetType  : JAccount
        as          : 'follower'
      likedBy       :
        targetType  : JAccount
        as          : 'like'
      user          :
        targetType  : JAccount
        as          : 'user'
      tag           :
        targetType  : JTag
        as          : 'tag'

    # TODO: this should be a race not a daisy

  @create = secure (client, data, callback)->

    console.log "creating the JApp"

    {connection:{delegate}} = client

    app = new JApp {
      title       : data.title
      body        : data.body
      manifest    : data.manifest
    }

    app.save (err)->
      if err
        callback err
      else
        app.addCreator delegate, (err)->
          if err
            callback err
          else
            callback null, app

  checkIfLikedBefore: secure ({connection}, callback)->
    {delegate} = connection
    {constructor} = @
    Relationship.one
      sourceId: @getId()
      targetId: delegate.getId()
      as: 'like'
    , (err, likedBy)=>
      if likedBy
        callback null, yes
      else
        callback err, no

  like: secure ({connection}, callback)->
    {delegate} = connection
    {constructor} = @
    unless delegate instanceof constructor.getAuthorType()
      callback new Error 'Only instances of JAccount can like things.'
    else
      Relationship.one
        sourceId: @getId()
        targetId: delegate.getId()
        as: 'like'
      , (err, likedBy)=>
        if err
          callback err
        else
          unless likedBy
            @addLikedBy delegate, respondWithCount: yes, (err, docs, count)=>
              if err
                callback err
              else
                @update ($set: 'meta.likes': count), callback
          else
            @removeLikedBy delegate, respondWithCount: yes, (err, count)=>
              if err
                callback err
                console.log err
              else
                @update ($set: 'meta.likes': count), callback

  install: secure ({connection}, callback)->
    {delegate} = connection
    {constructor} = @
    unless delegate instanceof constructor.getAuthorType()
      callback new Error 'Only instances of JAccount can install apps.'
    else
      Relationship.one
        sourceId: @getId()
        targetId: delegate.getId()
        as: 'user'
      , (err, installedBefore)=>
        if err
          callback err
        else
          unless installedBefore
            @addUser delegate, respondWithCount: yes, (err, docs, count)=>
              if err
                callback err
              else
                @update ($set: 'counts.installed': count), (err)=>
                  if err then callback err
                  else
                    Relationship.one
                      sourceId: @getId()
                      targetId: delegate.getId()
                      as: 'user'
                    , (err, relation)=>
                      CBucket.addActivities relation, @, delegate, (err)=>
                        if err
                          callback err
                        else
                          callback null
          else
            callback new KodingError 'Relationship already exists, App already installed'

  # @create = secure (client, data, callback)->

  #   console.log "creating the JApp"

  #   {connection:{delegate}} = client
  #   {thumbnails, screenshots, meta:{tags}} = data

  #   console.log thumbnails, screenshots, meta, ":::::"

  #   Resource.storeImages client, thumbnails, (err, thumbnailsFilenames)->
  #     if err
  #       callback err
  #       console.log "error 1"
  #     else
  #       Resource.storeImages client, screenshots, (err, screenshotsFilenames)->
  #         if err
  #           callback err
  #           console.log "error 2"
  #         else
  #           app = new JApp {
  #             title       : data.title
  #             body        : data.body
  #             manifest    : data.manifest
  #             thumbnails  : thumbnailsFilenames
  #             screenshots : screenshotsFilenames
  #             attachments : [
  #               {
  #                 as          : 'script'
  #                 content     : data.scriptCode
  #                 description : data.scriptDescription
  #                 syntax      : data.scriptSyntax
  #               },{
  #                 as          : 'requirements'
  #                 content     : data.requirementsCode
  #                 syntax      : data.requirementsSyntax
  #               }
  #             ]
  #           }
  #           app.save (err)->
  #             if err
  #               console.log "error 3"
  #               callback err
  #             else
  #               if tags then app.addTags client, tags, (err)->
  #                 if err
  #                   callback err
  #                   console.log "error 4"
  #                 else
  #                   callback null, app

  @findSuggestions = (seed, options, callback)->
    {limit,blacklist}  = options

    @some {
      title   : seed
      _id     :
        $nin  : blacklist
    },{
      limit
      sort    : 'title' : 1
    }, callback

