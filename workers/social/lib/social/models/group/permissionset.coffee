async                    = require 'async'
cacheManager             = require 'cache-manager'
{ Model, secure, }       = require 'bongo'
{ Module, Relationship } = require 'jraphical'

module.exports = class JPermissionSet extends Module

  @share()

  @set
    softDelete              : yes
    indexes                 :
      'permissions.module'  : 'sparse'
      'permissions.roles'   : 'sparse'
      'permissions.title'   : 'sparse'
    sharedEvents            :
      static                : []
      instance              : []
    schema                  :
      isCustom              :
        type                : Boolean
        default             : yes
      permissions           :
        type                : [ Object ]
        default             : -> []

  { intersection } = require 'underscore'

  KodingError = require '../../error'

  MAIN_GROUP = 'koding'

  constructor: (data = {}, options = {}) ->

    super data

    return  if @isCustom

    # initialize the permission set with some sane defaults:
    { permissionDefaultsByModule } = require '../../traits/protected'
    permissionsByRole = {}

    options.privacy ?= 'public'
    for own module, modulePerms of permissionDefaultsByModule
      for own perm, roles of modulePerms
        if roles.public? or roles.private?
          roles = roles[options.privacy] ?= []
        for role in roles
          permissionsByRole[module]       ?= {}
          permissionsByRole[module][role] ?= []
          permissionsByRole[module][role].push perm

    @permissions = []
    for own module, moduleRoles of permissionsByRole
      for own role, modulePerms of moduleRoles
        @permissions.push { module, role, permissions: modulePerms }


  @wrapPermission = wrapPermission = (permission) ->
    [{ permission, validateWith: require('./validators').any }]


  memCache = cacheManager.caching
    store  : 'memory'
    ttl    : 60 # seconds


  fetchGroupAndPermissionSet = do (queue = {}) ->

    fetcher = (groupName, callback) ->
      JGroup = require '../group'
      JGroup.one { slug: groupName }, (err, group) ->
        if err then callback err
        else unless group?
          callback new KodingError "Unknown group! #{groupName}"
        else
          group.fetchPermissionSetOrDefault (err, permissionSet) ->
            if err then callback err
            else callback null, { group, permissionSet }

    (groupName, callback) ->

      memCache.get groupName, (err, data) ->
        return callback err, data  if data

        queue[groupName] ?= []
        return  if (queue[groupName].push callback) > 1

        fetcher groupName, (err, data) ->

          if err
            cb err  for cb in queue[groupName]
          else
            memCache.set groupName, data  if data
            cb null, data  for cb in queue[groupName]

          queue[groupName] = []


  @expireCache = (group) -> memCache.del group


  getGroupnameFrom = (target, client) ->
    JGroup = require '../group'
    return if 'function' is typeof target
      client?.context?.group ? MAIN_GROUP
    else if target instanceof JGroup
      target.slug
    else
      target.group ? client?.context?.group ? MAIN_GROUP


  @checkPermission = (client, advanced, target, args, callback) ->

    advanced     = wrapPermission advanced  if 'string' is typeof advanced
    anyValidator = (require './validators').any
    currentGroup = client?.context?.group ? MAIN_GROUP

    # permission checker helper, walks on the all required permissions
    # if one of them passes, breaks the loop and returns true
    kallback = (current, main) ->

      # we will keep the passed advanced permission index
      # so based on this information we can get information
      # about the permission owner ~ GG
      permissionIndex = -1
      hasPermission = no

      queue = advanced.map ({ permission, validateWith, superadmin }, _permIndex) -> (next) ->

        return next()  if hasPermission

        if superadmin

          # if permission requires superadmin and current group is not 'koding'
          # or if somehow 'koding' group (main) not exists then pass ~ GG
          if currentGroup isnt MAIN_GROUP or not main
            return next()

          # if permission requires superadmin then do the permission check on
          # main group and permissionSet (which is 'koding' group) ~ GG
          { group, permissionSet } = main

        else

          { group, permissionSet } = current

        # use Validators.any if it's not provided
        validateWith ?= anyValidator

        validateWith.call target, client, group, permission, permissionSet, args,
          (err, _hasPermission) ->
            if _hasPermission
              hasPermission = _hasPermission
              permissionIndex = _permIndex
            next err

      async.series queue, (err) ->
        callback err, hasPermission, permissionIndex

    # set groupName from given target or client
    client.groupName = getGroupnameFrom target, client

    fetchGroupAndPermissionSet MAIN_GROUP, (err, main) ->
      return callback err, no  if err or not main

      # if it's the main group fetching only that one is enough
      if client.groupName is MAIN_GROUP
        kallback main, main # pass same group and permissionSet for
                            # current and the main group ~ GG
      else
        # fetch permission set for the given group and start checking permissions
        fetchGroupAndPermissionSet client.groupName, (err, current) ->
          if err or not current then callback err, no
          else kallback current, main


  @permit = (permission, promise) ->

    # parameter hockey to allow either parameter to be optional
    if arguments.length is 1 and 'string' isnt typeof permission
      [ promise, permission ] = [ permission, promise ]
    promise ?= {}

    # convert simple rules to complex rules:
    advanced =
      if promise.advanced then promise.advanced
      else wrapPermission permission

    # Support a "stub" form of permit that simply calls back with yes if the
    # permission is supported:
    promise.success ?= (client, callback) -> callback null, yes

    # return the validator:
    permit = secure (client, rest...) ->

      if 'function' is typeof rest[rest.length - 1]
        [rest..., callback] = rest
      else
        callback = (->)

      # success/failure functions assignment
      success =
        if 'function' is typeof promise then promise.bind this
        else promise.success.bind this
      failure = promise.failure?.bind this

      module =
        if 'function' is typeof this then @name
        else @constructor.name

      permissions = (p.permission for p in advanced).join ', '

      JPermissionSet.checkPermission client, advanced, this, rest,
        (err, hasPermission, permissionIndex) ->
          args = [client, rest..., callback]
          if err then callback err
          else if hasPermission
            # client._allowedPermissionIndex
            #
            # if you write something like this;
            #
            #   foo: permit
            #
            #     advanced: [
            #       { permission   : 'some permission', validateWith: Validators.own }
            #       {
            #         permission   : 'access related'
            #         validateWith : accessValidator ACCESSLEVEL.READ
            #       }
            #       { permission   : 'modify object', superadmin: yes }
            #     ]
            #
            #     success: (client, callback) ->
            #       ...
            #
            # and this permission is granted because you were a superadmin then
            # client._allowedPermissionIndex will become 2. But if you are owner of
            # this instance this time it will become 0 because the first rule granted.
            args[0]._allowedPermissionIndex = permissionIndex
            success.apply null, args
          else if failure?
            failure.apply null, args
          else

            try
              { context: { group }, clientIP, connection } = client
              { profile: { nickname } } = connection.delegate
              from = "'#{nickname}' on '#{group}' group. ip: '#{clientIP}'"
            catch
              from = "unknown: #{args}"

            console.log \
              "[#{module}] permission '#{permissions}' denied for #{from}"

            callback new KodingError 'Access denied'
