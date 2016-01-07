module.exports = class Protected

  { ObjectId } = require 'bongo'

  { extend } = require 'underscore'

  Protected.permissionsByModule = {}
  Protected.permissionDefaultsByModule = {}

  @setRelationships = do ->
    setRelationships = (relationships) ->
      { Module } = require 'jraphical'
      if 'function' is typeof relationships
        relationships = relationships()
      relationships.group =
        targetType  : require '../models/group'
        as          : ['member', 'moderator', 'admin']
      Module.setRelationships.call this, relationships
    (relationships) ->
      if 'function' is typeof relationships
        # when you pass "relationships" as a function, it will be defered until the next tick.
        # this can be useful for resolving circular dependencies (a requirement for graphs).
        process.nextTick setRelationships.bind this, relationships
      else
        setRelationships.call this, relationships
      this

  @setPermissions = (permissions) ->
    perms = Protected.permissionsByModule[@name] ?= []
    Protected.permissionsByModule[@name] = perms.concat Object.keys permissions
    defaults = Protected.permissionDefaultsByModule[@name] ?= {}
    extend defaults, permissions
