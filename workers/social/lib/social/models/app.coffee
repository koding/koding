jraphical   = require 'jraphical'
KodingError = require '../error'
{argv}      = require 'optimist'
KONFIG      = require('koding-config-manager').load("main.#{argv.c}")

module.exports = class JNewApp extends jraphical.Module

  JAccount  = require './account'
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
        enum            : ["Wrong type specified!",
          ["web-app", "add-on", "server-stack", "framework"]
        ]
        default         : "web-app"

      status            :
        type            : String
        enum            : ["Wrong status specified!",
          ["verified", "not-verified", "github-verified"]
        ]
        default         : "not-verified"

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
    if not data.name or not data.url or not data.manifest
      return new KodingError 'Name, Url and Manifest is required!'
    unless typeof(data.manifest) is 'object'
      return new KodingError 'Manifest should be an object!'

  validateUrl = (account, url, callback)->

    url = url.replace /\/$/, ''
    urls =
      script : "#{url}/index.js"
      style  : "#{url}/resources/style.css"

    # If url points to a vm url
    if (/^\[([^\]]+)\]/g.exec url)?[1]
      return callback null, urls

    {appsUri} = KONFIG.client.runtimeOptions

    urlParser =
      ///
        ^#{appsUri}\/           # Should start with appsUri (in config.client)
        ([a-z0-9\-]+)\/         # Username
        ([a-z0-9\-]+)\.kdapp\/  # App name
        ([a-z0-9\-]+)$          # Git branch/commit id (usually master)
      ///i

    [url, githubUsername, app, branch] = (urlParser.exec url) or []

    unless githubUsername
      return callback new KodingError "URL is not allowed."

    # If user is admin
    if account.can 'bypass-validations'
      return callback null, urls, {githubVerified: yes, app, githubUsername}

    account.fetchUser (err, user)->
      return callback err  if err?

      unless user.foreignAuth?.github?
        return callback new KodingError \
          "There is no linked GitHub account with this account."

      {username} = user.foreignAuth.github
      if username is not githubUsername
        return callback new KodingError "Remote username mismatch."

      app = app.replace /\.kdapp$/, ''
      # TODO - Add existence check from remote url ~ GG
      callback null, urls, {githubVerified: yes, app, githubUsername}

  # TODO ~ GG

  @publish = permit 'create apps',

    success: (client, data, callback)->

      {connection:{delegate}} = client
      {profile} = delegate

      console.info "publishing the JNewApp of #{profile.nickname}"

      if validationError = checkData data, profile
        return callback validationError

      validateUrl delegate, data.url, (err, urls, details)=>
        return callback err  if err

        data.urls = urls
        data.name = capitalize @slugify data.name

        # Make sure the app name and the GitHub url matches if exists
        if details?
          if details.app isnt data.name
            return callback \
              new KodingError "GitHub repository and application name mismatch."

          data.manifest.repository = \
            "git://github.com/#{details.githubUsername}/#{details.app}.kdapp"

        # Overwrite the user/app information in manifest
        data.manifest.name       = data.name
        data.manifest.authorNick = profile.nickname
        data.manifest.author     = "#{profile.firstName} #{profile.lastName}"

        # Optionals
        data.manifest.version   ?= "1.0"
        data.identifier         ?= "com.koding.apps.#{data.name.toLowerCase()}"

        {authorNick} = data.manifest

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
            status      : if details?.githubVerified? \
                          then 'github-verified' else 'not-verified'

          if app

            app.update $set: appData, (err)->
              return callback err  if err
              callback null, app

          else

            app = new JNewApp appData
            app.save (err)->
              return callback err  if err
              slug = "#{app.manifest.authorNick}/Apps/#{app.name}"
              app.useSlug slug, (err, slugobj)->
                if err then return app.remove -> callback err
                slug = slugobj.slug
                app.update {$set: {slug, slug_: slug}}, (err)->
                  console.warn "Slug update failed for #{slug}", err  if err
                app.addCreator delegate, (err)->
                  return callback err  if err
                  callback null, app

  getDefaultSelector = (client, selector)->
    {delegate}   = client.connection
    selector   or= {}
    selector.$or = [
      {status    : $ne : 'not-verified'}
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

        status = if state then 'verified' else 'not-verified'
        @update $set: {status}, callback
