module.exports = class Groupable

  {permit} = require '../models/group/permissionset.coffee'

  helpers = require 'bongo/lib/model/find-via-collection'

  {Inflector} = require 'bongo'

  getCollection =(konstructor, client)->
    {name} = konstructor
    db = konstructor.getClient()
    {group} = client.context
    return db.collection "#{Inflector.pluralize name}__#{group.replace /-/g, '_'}"

  @drop = permit 'drop collection'
    success:(client, callback)->
      collection = getCollection this, client
      helpers.drop.call this, collection, callback
      return this

  @one = permit 'query collection'
    success:(client, uniqueSelector, options, callback)->
      collection = getCollection this, client
      helpers.one.call this, collection, uniqueSelector, options, callback
      return this

  @all = permit 'query collection'
    success:(client, selector, callback)->
      collection = getCollection this, client
      helpers.all.call this, collection, selector, callback
      return this

  @remove = permit 'query collection'
    success:(client, selector, callback)->
      collection = getCollection this, client
      helpers.remove.call this, collection, selector, callback
      return this

  @count = permit 'query collection'
    success:(client, selector, callback)->
      collection = getCollection this, client
      helpers.count.call this, collection, selector, callback
      return this

  @some = permit 'query collection'
    success:(client, selector, options, callback)->
      collection = getCollection this, client
      helpers.some.call this, collection, selector, options, callback
      return this

  @someData = permit 'query collection'
    success:(client, selector, fields, options, callback)->
      collection = getCollection this, client
      helpers.someData.call this, collection, selector, fields, options, callback
      return this