jraphical   = require 'jraphical'
KodingError = require '../error'

module.exports = class JApp extends jraphical.Module

  JAccount  = require './account'
  JReview   = require './messages/review'
  JTag      = require './tag'

  @trait __dirname, '../traits/filterable'       # brings only static methods
  @trait __dirname, '../traits/followable'
  @trait __dirname, '../traits/taggable'
  @trait __dirname, '../traits/likeable'
  @trait __dirname, '../traits/slugifiable'
  @trait __dirname, '../traits/protected'

  {permit}   = require './group/permissionset'
  Validators = require './group/validators'

  #
  {Inflector,JsPath,secure,daisy,ObjectId,ObjectRef} = require 'bongo'
  {Relationship} = jraphical

  @share()

  @set

    softDelete          : yes

    indexes             :
      slug              : 'unique'
      name              : 'sparse'

    sharedEvents        :
      instance          : [
        { name: 'ReviewIsAdded' }
      ]

    sharedMethods       :
      instance          : [
        'fetchRelativeReviews', 'review', 'delete'
      ]
      static            : [
        'create', 'someWithRelationship', 'one', 'some', 'each'
      ]

    permissions         :

      'list apps'       : ['member']
      'create apps'     : ['member']
      'update own apps' : ['member']
      'delete own apps' : ['member']
      'list reviews'    : ['member']
      'create review'   : ['member']
      'approve apps'    : []
      'delete apps'     : []
      'update apps'     : []
      'list all apps'   : []

    schema              :

      authorNick        : String
      identifier        :
        type            : String
        set             : (value)-> value?.trim()
        required        : yes
      name              :
        type            : String
        set             : (value)-> value?.trim()
        required        : yes
      url               :
        type            : String
        set             : (value)-> value?.trim()
        required        : yes
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

    relationships       :
      creator           :
        targetType      : JAccount
        as              : "creator"
      review            :
        targetType      : JReview
        as              : "review"
      follower          :
        targetType      : JAccount
        as              : 'follower'
      likedBy           :
        targetType      : JAccount
        as              : 'like'
      participant       :
        targetType      : JAccount
        as              : ['author','reviewer','user']
      tag               :
        targetType      : JTag
        as              : 'tag'

  @getAuthorType =-> JAccount

  @create = permit 'create apps',

    success: (client, data, callback)->

      console.log "creating the JApp"

      {connection:{delegate}} = client
      {profile} = delegate

      if not data.name or not data.url
        return callback new KodingError 'Name and Url is required!'

      data.manifest           ?= {}

      # Overwrite the user information in manifest
      data.manifest.authorNick = profile.nickname
      data.manifest.author     = "#{profile.firstName} #{profile.lastName}"

      # Optionals
      data.manifest.version   ?= "1.0"
      data.identifier         ?= "com.koding.apps.#{data.name}"

      app           = new JApp
        url         : data.url
        name        : data.name
        type        : data.type or 'web-app'
        manifest    : data.manifest
        identifier  : data.identifier
        version     : data.manifest.version
        authorNick  : data.manifest.authorNick

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
          slug = "#{app.authorNick}/#{app.name}"
          app.useSlug slug, (err, slugobj)->
            return callback err  if err
            slug = slugobj.slug
            app.update {$set: {slug, slug_: slug}}, (err)->
              return callback err  if err
              callback null, app

  approve: permit 'approve apps',

    success: (client, state = yes, callback)->

      unless state
        return @update approved: no, callback

      identifier = @getAt 'identifier'

      JApp.count {identifier, approved:yes}, (count)=>

        # Check if any app used same identifier and already approved
        if count > 1
          return callback new KodingError \
                 'Identifier already in use, please change it first'


  # approve: permit 'approve apps',

  #   success: (client, state = yes, callback)->

  #     # Disapprove
  #     unless state

  #       return @update $set:{approved: no}, callback

  #     identifier = @getAt 'identifier'

  #     JApp.count {identifier, approved:yes}, (count)=>

  #       # Check if any app used same identifier and already approved
  #       if count > 1
  #         return callback new KodingError \
  #                'Identifier already in use, please change it first'

  #       # Check if the app has a slug, if not create one
  #       unless @getAt 'slug'
  #         this.createSlug (err, slug)=>
  #           return callback err  if err
  #           slug = slug_ = slug.slug
  #           @update {slug, slug_, approved:yes}, callback
  #       else
  #         @update approved:yes, callback

  # JApp.one
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
    #           JApp.one
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
    #               approval_app = new JApp
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
    #       app = new JApp
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

  #         JApp.one
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
  #                       # @delete We can delete the temporary JApp (@) here.
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
  #     sourceType: 'JApp'
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
