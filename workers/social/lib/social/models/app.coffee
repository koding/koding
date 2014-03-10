jraphical   = require 'jraphical'
KodingError = require '../error'

module.exports = class JNewApp extends jraphical.Module

  JAccount  = require './account'
  JReview   = require './messages/review'
  JTag      = require './tag'
  JName     = require './name'

  @trait __dirname, '../traits/filterable'       # brings only static methods
  @trait __dirname, '../traits/followable'
  @trait __dirname, '../traits/taggable'
  @trait __dirname, '../traits/likeable'
  @trait __dirname, '../traits/slugifiable'
  @trait __dirname, '../traits/protected'

  {permit}   = require './group/permissionset'
  Validators = require './group/validators'

  #
  {Inflector, JsPath, secure, daisy, ObjectId, ObjectRef, signature} = require 'bongo'
  {Relationship} = jraphical

  @share()

  @set

    softDelete          : yes

    indexes             :
      slug              : 'unique'
      name              : 'sparse'

    sharedEvents        :
      instance          : [
        { name: 'updateInstance' }
        { name: 'ReviewIsAdded' }
      ]
      static            : []

    sharedMethods       :
      instance          :
        delete          :
          (signature Function)
        approve         : [
          (signature Function)
          (signature Boolean, Function)
        ]

      static            :
        publish         :
          (signature Object, Function)
        one             :
          (signature Object, Function)
        some            :
          (signature Object, Object, Function)
        some_           :
          (signature Object, Object, Function)
        each            : [
          (signature Object, Function)
          (signature Object, Object, Function)
        ]
        byRelevance     : [
          (signature String, Function)
          (signature String, Object, Function)
        ]

    permissions         :

      'list apps'       : ['member']
      'create apps'     : ['member']
      'update own apps' : ['member']
      'delete own apps' : ['member']
      'approve apps'    : []
      'delete apps'     : []
      'update apps'     : []
      'list all apps'   : []

    schema              :

      identifier        :
        type            : String
        set             : (value)-> value?.trim()
        required        : yes
      name              :
        type            : String
        set             : (value)-> value?.trim()
        required        : yes
      title             : String
      urls              :
        script          :
          type          : String
          set           : (value)-> value?.trim()
          required      : yes
        style           :
          type          : String
          set           : (value)-> value?.trim()
      repourl           :
        type            : String
        set             : (value)-> value?.trim()
      counts            :
        followers       :
          type          : Number
          default       : 0
        installed       :
          type          : Number
          default       : 0

      versions          : [String]

      meta              : require "bongo/bundles/meta"
      manifest          : Object

      type              :
        type            : String
        enum            : ["Wrong type specified!",["web-app", "add-on", "server-stack", "framework"]]
        default         : "web-app"

      approved          :
        type            : Boolean
        default         : false

      repliesCount      :
        type            : Number
        default         : 0

      slug              :
        type            : String
        default         : (value)-> Inflector.slugify @name.toLowerCase()
      slug_             : String

      originId          :
        type            : ObjectId
        required        : yes

      group             : String

    relationships       :
      creator           :
        targetType      : JAccount
        as              : "creator"

  @getAuthorType =-> JAccount

  capitalize = (str)-> str.charAt(0).toUpperCase() + str.slice(1)

  @byRelevance$ = permit 'list apps',
    success: (client, seed, options, callback)->
      @byRelevance client, seed, options, callback

  @findSuggestions = (client, seed, options, callback)->
    {limit, blacklist, skip}  = options
    names = seed.toString().split('/')[1].replace('^','')
    @some {
      $or : [
          ( 'name'  : new RegExp names, 'i' )
          ( 'title' : new RegExp names, 'i' )
        ]
      _id     :
        $nin  : blacklist
      },{skip, limit}, callback


  checkData = (data, profile)->
    unless data.name or data.urls?.script or data.manifest
      return new KodingError 'Name, Url and Manifest is required!'
    unless typeof(data.manifest) is 'object'
      return new KodingError 'Manifest should be an object!'
    unless data.manifest.authorNick is profile.nickname
      return new KodingError 'Authornick in manifest is different from your username!'


  # TODO ~ GG
  # - Add updated version field, and do not allow to change urls if it approved

  @publish = permit 'create apps',

    success: (client, data, callback)->

      console.log "publishing the JNewApp"

      {connection:{delegate}} = client
      {profile} = delegate

      if validationError = checkData data, profile
        return callback validationError

      data.name = capitalize @slugify data.name
      {name, manifest:{authorNick}} = data

      # Overwrite the user/app information in manifest
      data.manifest.name       = data.name
      data.manifest.authorNick = profile.nickname
      data.manifest.author     = "#{profile.firstName} #{profile.lastName}"

      # Optionals
      data.manifest.version   ?= "1.0"
      data.identifier         ?= "com.koding.apps.#{data.name.toLowerCase()}"

      JNewApp.one {name, 'manifest.authorNick':authorNick}, (err, app)->

        return callback err  if err

        appData =
          name        : data.name
          title       : data.name
          urls        : data.urls
          type        : data.type or 'web-app'
          manifest    : data.manifest
          identifier  : data.identifier
          version     : data.manifest.version
          originId    : delegate.getId()
          group       : client.context.group

        if app

          app.update $set: appData, (err)->
            return callback err  if err
            callback null, app

        else

          app = new JNewApp appData
          app.save (err)->
            return callback err  if err
            slug = "Apps/#{app.manifest.authorNick}/#{app.name}"
            app.useSlug slug, (err, slugobj)->
              if err then return app.remove -> callback err
              slug = slugobj.slug
              app.update {$set: {slug, slug_: slug}}, (err)->
                console.warn "Slug update failed for #{slug}", err  if err
              app.addCreator delegate, (err)->
                return callback err  if err
                callback null, app


  @create = permit 'create apps',

    success: (client, data, callback)->

      console.log "creating the JNewApp"

      {connection:{delegate}} = client
      {profile} = delegate

      if not data.name or not data.urls?.script
        return callback new KodingError 'Name and Url is required!'

      data.name = capitalize @slugify data.name

      data.manifest           ?= {}

      # Overwrite the user/app information in manifest
      data.manifest.name       = data.name
      data.manifest.authorNick = profile.nickname
      data.manifest.author     = "#{profile.firstName} #{profile.lastName}"

      # Optionals
      data.manifest.version   ?= "1.0"
      data.identifier         ?= "com.koding.apps.#{data.name.toLowerCase()}"

      app           = new JNewApp
        name        : data.name
        title       : data.name
        urls        : data.urls
        type        : data.type or 'web-app'
        manifest    : data.manifest
        identifier  : data.identifier
        version     : data.manifest.version
        originId    : delegate.getId()
        group       : client.context.group

      app.save (err)->
        return callback err  if err
        slug = "Apps/#{app.manifest.authorNick}/#{app.name}"
        app.useSlug slug, (err, slugobj)->
          if err then return app.remove -> callback err
          slug = slugobj.slug
          app.update {$set: {slug, slug_: slug}}, (err)->
            console.warn "Slug update failed for #{slug}", err  if err
          app.addCreator delegate, (err)->
            return callback err  if err
            callback null, app

          return callback err  if err
              return callback err  if err
              callback null, review

              @fetchCreator (err, origin)=>
                return console.error "JNewApp:", err  if err
                @emit 'ReviewIsAdded',
                  origin        : origin
                  subject       : ObjectRef(@).data
                  actorType     : 'reviewer'
                  actionType    : 'review'
                  replier       : ObjectRef(delegate).data
                  reply         : ObjectRef(review).data
                  repliesCount  : count
                  relationship  : docs[0]

                @follow client, emitActivity: no, (err)->
                  console.error "JNewApp:", err  if err
                @addParticipant delegate, 'reviewer', (err)->
                  console.error "JNewApp:", err  if err

  getDefaultSelector = (client, selector)->
    {delegate}   = client.connection
    selector   or= {}
    selector.$or = [
      {approved  : yes}
      {originId  : delegate.getId()}
    ]
    return selector

  @some_: permit 'list all apps',

    success: (client, selector, options, callback)->

      @some selector, options, callback

  @some$: permit 'list apps',

    success: (client, selector, options, callback)->

      selector  = getDefaultSelector client, selector
      options or= {}
      options.limit = Math.min(options.limit or 0, 10)

      @some selector, options, callback

  @one$ = permit 'list apps',

    success: (client, selector, options, callback)->

      # selector = getDefaultSelector client, selector
      [options, callback] = [callback, options] unless callback

      @one selector, options, callback

  @each$: permit 'list apps',

    success: (client, selector, fields, options, callback)->

      selector = getDefaultSelector client, selector
      @each selector, fields, options, callback

  delete: permit

    advanced: [
      { permission: 'delete own apps', validateWith: Validators.own }
      { permission: 'delete apps' }
    ]

    success: (client, callback)->
      @remove callback

      removeJNames = (names)->
        names.forEach (name)->
          JName.one {name}, (err, jname)->
            return console.error "Failed to get JName: ", err  if err
            jname?.remove (err)->
              console.error "Failed to remove JName: ", err  if err

      removeJNames [@name, @slug]

  approve: permit 'approve apps',

    success: (client, state, callback)->
      [callback, state] = [state, callback]  unless callback

      state ?= yes

      JName.one {@name}, (err, jname)=>

        return callback err  if err

        if state is no and jname
          if @slug is jname.slugs[0].slug
            jname.remove (err)->
              console.error "Failed to remove JName: ", err  if err

        else

          unless jname

            name = new JName
              name  : @name
              slugs : [
                constructorName : 'JNewApp'
                collectionName  : 'jNewApps'
                slug            : @slug
                usedAsPath      : 'slug'
              ]

            name.save (err) ->
              console.error "Failed to save JName: ", err  if err

        @update $set: approved: state, callback

      # identifier = @getAt 'identifier'

      # JNewApp.count {identifier, approved:yes}, (count)=>

      #   # Check if any app used same identifier and already approved
      #   if count > 1
      #     return callback new KodingError \
      #            'Identifier already in use, please change it first'




      #   # Check if the app has a slug, if not create one
      #   unless @getAt 'slug'
      #     this.createSlug (err, slug)=>
      #       return callback err  if err
      #       slug = slug_ = slug.slug
      #       @update {slug, slug_, approved:yes}, callback
      #   else
      #     @update approved:yes, callback

  # JNewApp.one
    #   name : data.name
    # , (err, app)=>
    #   if err
    #     callback err
    #   else
    #     # Override author info with delegate
    #     data.manifest.authorNick = delegate.getAt 'profile.nickname'
    #     data.manifest.author = "#{delegate.getAt 'profile.firstName'} #{delegate.getAt 'profile.lastName'}"

    #     if app
    #       if String(app.originId) isnt String(delegate.getId()) and not delegate.can('approve', this)
    #         callback new KodingError 'Identifier belongs to different user.'
    #       else
    #         console.log "alreadyPublished trying to update fields"

    #         if app.approved # So, this is just a new update
    #           # Lets look if already waiting for approve
    #           JNewApp.one
    #             identifier : "waits.for.approve:#{data.identifier}"
    #           , (err, approval_app)=>
    #             if approval_app
    #               # means no one approved the update before this update
    #               approval_app.update
    #                 $set:
    #                   title     : data.title
    #                   body      : data.body
    #                   manifest  : data.manifest
    #                   approved  : no
    #               , (err)->
    #                 if err then callback err
    #                 else callback null, approval_app

    #             else
    #               approval_slug = "#{app.slug}-#{data.manifest.version}-waits-for-approve"
    #               approval_app = new JNewApp
    #                 title       : data.title
    #                 body        : data.body
    #                 manifest    : data.manifest
    #                 originId    : delegate.getId()
    #                 slug        : approval_slug
    #                 slug_       : approval_slug
    #                 originType  : delegate.constructor.name
    #                 identifier  : "waits.for.approve:#{data.identifier}"

    #               approval_app.save (err)->
    #                 if err
    #                   callback err
    #                 else
    #                   callback null, app

    #         else
    #           if not data.manifest.version
    #             callback new KodingError 'Version is not provided.'
    #           else
    #             curVersions = app.data.versions
    #             versionExists = (curVersions[i] for i in [0..curVersions.length] when curVersions[i] is data.manifest.version).length

    #           if versionExists
    #             callback new KodingError 'Version already exists, update version to publish.'
    #           else
    #             app.update
    #               $set:
    #                 title     : data.title
    #                 body      : data.body
    #                 manifest  : data.manifest
    #                 approved  : no # After each update on an app we need to reapprove it
    #               $addToSet   :
    #                 versions  : data.manifest.version
    #             , (err)->
    #               if err then callback err
    #               else callback null, app

    #     else
    #       app = new JNewApp
    #         title       : data.title
    #         body        : data.body
    #         manifest    : data.manifest
    #         originId    : delegate.getId()
    #         originType  : delegate.constructor.name
    #         identifier  : data.identifier
    #         versions    : [data.manifest.version]

    #       app.createSlug (err, slug)->
    #         if err
    #           callback err
    #         else
    #           app.slug   = slug.slug
    #           app.slug_  = slug.slug
    #           app.save (err)->
    #             if err
    #               callback err
    #             else
    #               app.addCreator delegate, (err)->
    #                 if err
    #                   callback err
    #                 else
    #                   callback null, app

  # @create = permit 'create apps',

  #   success: (client, data, callback)->

  #     console.log "creating the JNewApp"

  #     {connection:{delegate}} = client
  #     {profile} = delegate

  #     if not data.name or not data.urls?.script
  #       return callback new KodingError 'Name and Url is required!'

  #     data.name = capitalize @slugify data.name

  #     data.manifest           ?= {}

  #     # Overwrite the user/app information in manifest
  #     data.manifest.name       = data.name
  #     data.manifest.authorNick = profile.nickname
  #     data.manifest.author     = "#{profile.firstName} #{profile.lastName}"

  #     # Optionals
  #     data.manifest.version   ?= "1.0"
  #     data.identifier         ?= "com.koding.apps.#{data.name.toLowerCase()}"

  #     app           = new JNewApp
  #       name        : data.name
  #       title       : data.name
  #       urls        : data.urls
  #       type        : data.type or 'web-app'
  #       manifest    : data.manifest
  #       identifier  : data.identifier
  #       version     : data.manifest.version
  #       originId    : delegate.getId()
  #       group       : client.context.group

  #     app.save (err)->
  #       return callback err  if err
  #       slug = "Apps/#{app.manifest.authorNick}/#{app.name}"
  #       app.useSlug slug, (err, slugobj)->
  #         if err then return app.remove -> callback err
  #         slug = slugobj.slug
  #         app.update {$set: {slug, slug_: slug}}, (err)->
  #           console.warn "Slug update failed for #{slug}", err  if err
  #         app.addCreator delegate, (err)->
  #           return callback err  if err
  #           callback null, app

  # fetchRelativeReviews: permit 'list reviews',

  #   success: (client, {offset, limit, before, after}, callback)->

  #     limit  ?= 10
  #     offset ?= 0
  #     if before? and after?
  #       callback new KodingError "Don't use before and after together."
  #     selector = timestamp:
  #       if before? then  $lt: before
  #       else if after? then $gt: after
  #     options = {sort: timestamp: -1}
  #     if limit > 0
  #       options.limit = limit
  #     if offset > 0
  #       options.skip = offset
  #     @fetchReviews selector, options, callback

  # review: permit 'create review',

  #   success: (client, body, callback)->

  #     {delegate} = client.connection

  #     review = new JReview  { body }
  #     review.sign delegate
  #     review.save (err)=>
  #       return callback err  if err
  #       delegate.addContent review, (err)=>
  #         console.error 'JNewApp:', err  if err
  #       @addReview review, (err, docs)=>
  #         return callback err  if err
  #         Relationship.count
  #           sourceId : @getId()
  #           as       : 'review'
  #         , (err, count)=>
  #           return callback err  if err
  #           @update $set: repliesCount: count, (err)=>
  #             return callback err  if err
  #             callback null, review

  #             @fetchCreator (err, origin)=>
  #               return console.error "JNewApp:", err  if err
  #               @emit 'ReviewIsAdded',
  #                 origin        : origin
  #                 subject       : ObjectRef(@).data
  #                 actorType     : 'reviewer'
  #                 actionType    : 'review'
  #                 replier       : ObjectRef(delegate).data
  #                 reply         : ObjectRef(review).data
  #                 repliesCount  : count
  #                 relationship  : docs[0]

  #               @follow client, emitActivity: no, (err)->
  #                 console.error "JNewApp:", err  if err
  #               @addParticipant delegate, 'reviewer', (err)->
  #                 console.error "JNewApp:", err  if err

  # install: secure ({connection}, callback)->
  #   {delegate} = connection
  #   {constructor} = @
  #   unless delegate instanceof constructor.getAuthorType()
  #     callback new Error 'Only instances of JAccount can install apps.'
  #   else
  #     Relationship.one
  #       sourceId: @getId()
  #       targetId: delegate.getId()
  #       as: 'user'
  #     , (err, installedBefore)=>
  #       if err
  #         callback err
  #       else
  #         unless installedBefore
  #           # If itsn't an approved app so we dont need to create activity
  #           if @getAt 'approved'
  #             @addParticipant delegate, {as:'user', respondWithCount: yes}, (err, docs, count)=>
  #               if err
  #                 callback err
  #               else
  #                 @update ($set: 'counts.installed': count), (err)=>
  #                   if err then callback err
  #                   else
  #                     Relationship.one
  #                       sourceId: @getId()
  #                       targetId: delegate.getId()
  #                       as: 'user'
  #                     , (err, relation)=>
  #                       if err then callback err
  #                       else
  #                         CBucket.addActivities relation, @, delegate, null, (err)=>
  #                           if err
  #                             callback err
  #                           else
  #                             callback null
  #           else
  #             callback new KodingError 'App is not approved so activity is not created.'
  #         else
  #           callback null

  # approve: secure ({connection}, state = yes, callback)->

  #   {delegate} = connection
  #   {constructor} = @
  #   unless delegate instanceof constructor.getAuthorType()
  #     callback new KodingError 'Only instances of JAccount can approve apps.'
  #   else
  #     unless delegate.checkFlag 'super-admin'
  #       callback new KodingError 'Only Koding Application Admins can approve apps.'
  #     else
  #       if @getAt('identifier').indexOf('waits.for.approve:') is 0
  #         identifier = @getAt('identifier').replace 'waits.for.approve:', ''

  #         JNewApp.one
  #           identifier:identifier
  #         , (err, target)=>
  #           if err
  #             callback err
  #           else

  #             if target
  #               newVersion = @getAt 'manifest.version'

  #               if not newVersion
  #                 callback new KodingError 'Version is not provided.'
  #               else
  #                 curVersions = target.data.versions
  #                 versionExists = (curVersions[i] for i in [0..curVersions.length] when curVersions[i] is newVersion).length

  #                 if versionExists
  #                   callback new KodingError 'Version already approved, update version to reapprove.'
  #                 else
  #                   target.update
  #                     $set:
  #                       title     : @getAt 'title'
  #                       body      : @getAt 'body'
  #                       manifest  : @getAt 'manifest'
  #                       meta      : createdAt: new Date()
  #                       approved  : yes
  #                     $addToSet   :
  #                       versions  : @getAt 'manifest.version'
  #                   , (err)->
  #                     if err
  #                       console.log err
  #                       callback err
  #                     else
  #                       # @delete We can delete the temporary JNewApp (@) here.
  #                       callback null, target

  #             else
  #               callback new KodingError "Target (already approved application) not found!"

  #       else
  #         @update ($set: approved: state), (err)=>
  #           callback err

  # @markInstalled = secure (client, apps, callback)->
  #   Relationship.all
  #     targetId  : client.connection.delegate.getId()
  #     as        : 'user'
  #     sourceType: 'JNewApp'
  #   , (err, relationships)->
  #     apps.forEach (app)->
  #       app.installed = no
  #       for relationship, index in relationships
  #         if app._id is relationship.sourceId
  #           app.installed = yes
  #           relationships.splice index,1
  #           break
  #     callback err, apps

  # delete: secure ({connection:{delegate}}, callback)->

  #   if delegate.can 'delete', this
  #     @remove callback


  # # modify: permit
  # #   advanced: [
  # #     { permission: 'edit own posts', validateWith: Validators.own }
  # #     { permission: 'edit posts' }
  # #   ]
  # #   success: (client, formData, callback)->



  #   # if not (delegate.checkFlag('app-publisher') or delegate.checkFlag('super-admin'))
  #   #   callback new KodingError 'You are not authorized to publish apps.'
  #   #   return no

  #   # if data.identifier.indexOf('com.koding.apps.') isnt 0
  #   #   callback new KodingError 'Invalid identifier provided.'
  #   #   return no
