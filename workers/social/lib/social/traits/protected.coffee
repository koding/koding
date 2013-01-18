module.exports = class Protected

  {ObjectId} = require 'bongo'

  Protected.permissionsByModule = {}

  @setRelationships =do ->
    setRelationships =(relationships)->
      {Module} = require 'jraphical'
      if 'function' is typeof relationships
        relationships = relationships()
      relationships.group =
        targetType  : require '../models/group' 
        as          : ['member','moderator','admin']
      Module.setRelationships.call @, relationships      
    (relationships)->
      if 'function' is typeof relationships
        # when you pass "relationships" as a function, it will be defered until the next tick.
        # this can be useful for resolving circular dependencies (a requirement for graphs).
        process.nextTick setRelationships.bind @, relationships
      else
        setRelationships.call @, relationships
      @

  @setPermissions =(permissions)->
    perms = Protected.permissionsByModule[@name] ?= []
    Protected.permissionsByModule[@name] = perms.concat permissions
