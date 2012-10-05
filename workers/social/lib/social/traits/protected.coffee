module.exports = class Protected

  Protected.permissionsByModule = {}

  @setPermissions =(permissions)->
    perms = Protected.permissionsByModule[@name] ?= []
    Protected.permissionsByModule[@name] = perms.concat permissions
