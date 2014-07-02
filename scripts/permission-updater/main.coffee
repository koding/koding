Bongo = require 'bongo'
{ join: joinPath } = require 'path'

argv = require('minimist') process.argv

KONFIG = require('koding-config-manager').load("main.#{argv.c}")

mongo = "mongodb://#{ KONFIG.mongo }"

modelPath = '../../workers/social/lib/social/models'

koding = new Bongo
  root   : __dirname
  mongo  : mongo
  models : modelPath

done = ->
  console.log "Finished!"
  process.exit 1

workQueue = []

koding.once 'dbClientReady', ->
  JPermissionSet = require joinPath modelPath, 'group/permissionset.coffee'
  Protected = require joinPath modelPath, '../traits/protected.coffee'

  { permissionDefaultsByModule: defaults } = Protected

  JPermissionSet.each {}, {}, (err, permissionSet) ->
    return callback err  if err?

    unless permissionSet?
      if argv.hard?
        Bongo.dash workQueue, done
      else
        done()
      return

    console.log "BEFORE", permissionSet.permissions

    seen = {}
    missing = []

    # need to check to find missing permissions for roles already in the DB:
    for perms in permissionSet.permissions
      moduleDefaults = defaults[perms.module]
      continue  unless moduleDefaults?

      for own permission, roles of moduleDefaults when perms.role in roles
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

    console.log "AFTER", permissionSet.permissions

    if argv.hard
      workQueue.push -> permissionSet.save -> workQueue.fin()
