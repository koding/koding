# coffeelint: disable=cyclomatic_complexity

Bongo                   = require 'bongo'
async                   = require 'async'
{ join: joinPath }      = require 'path'
{ env : { MONGO_URL } } = process

argv = require('minimist') process.argv

KONFIG = require 'koding-config-manager'

mongo = MONGO_URL or "mongodb://#{KONFIG.mongo}"

modelPath = '../../workers/social/lib/social/models'

koding = new Bongo
  root   : __dirname
  mongo  : mongo
  models : modelPath

done = ->
  console.log 'Finished!'
  process.exit 1

inRoles = (role, roles) ->
  return role in roles  if Array.isArray roles
  # handle the special case that groups permissions are not copied over
  if ('public' of roles) and ('private' of roles)
    return role in roles.public  if role is 'guest'
    return role in roles.private
  no

workQueue = []

koding.once 'dbClientReady', ->
  JPermissionSet = require joinPath modelPath, 'group/permissionset.coffee'
  Protected = require joinPath modelPath, '../traits/protected.coffee'

  { permissionDefaultsByModule: defaults } = Protected

  JPermissionSet.each {}, {}, (err, permissionSet) ->
    console.error err  if err

    unless permissionSet?
      if argv.hard or argv.reset
        async.parallel workQueue, done
      else
        done()
      return

    if argv.reset

      newSet = new JPermissionSet {}, { privacy: 'public' }
      workQueue.push (fin) ->
        permissionSet.update {
          $set:
            permissions: newSet.permissions
        }, (err) ->
          console.log 'Failed to update permissions', err  if err
          fin()

      return

    console.log 'BEFORE', permissionSet.permissions

    seen = {}
    missing = []

    # need to check to find missing permissions for roles already in the DB:
    for perms in permissionSet.permissions
      moduleDefaults = defaults[perms.module]
      continue  unless moduleDefaults?

      for own permission, roles of moduleDefaults when inRoles perms.role, roles
        seen[perms.module] ?= {}
        seen[perms.module][perms.role] ?= {}
        seen[perms.module][perms.role][permission] ?= 1
        unless permission in perms.permissions
          missing.push
            module: perms.module
            role: perms.role
            permission: permission

    missing2 = []

    # need to add the missing permissions for roles that are not in the DB:
    for own defaultModule, defaultPermissions of defaults
      for own defaultPermission, defaultRoles of defaultPermissions
        for defaultRole in defaultRoles
          wasSeen = seen[defaultModule]?[defaultRole]?[defaultPermission]?
          unless wasSeen
            missing2.push
              module: defaultModule
              role: defaultRole
              permission: defaultPermission

    # now add the missing permissions for which we already have the roles:
    for mp in missing
      for perms in permissionSet.permissions when (perms.module is mp.module) and (perms.role is mp.role)
        perms.permissions.push mp.permission

    # now add the permissions for which we do not have the roles:
    pushes = missing2.reduce (memo, mp2) ->
      byRole = memo["#{ mp2.module }.#{ mp2.role }"] ?=
        module: mp2.module
        role: mp2.role
        permissions: []
      byRole.permissions.push mp2.permission
      return memo
    , {}

    for own _, missingSet of pushes
      permissionSet.permissions.push missingSet

    console.log 'AFTER', permissionSet.permissions

    if argv.hard
      workQueue.push (fin) -> permissionSet.save -> fin()
