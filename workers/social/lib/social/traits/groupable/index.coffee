module.exports = class Groupable

  @inCollectionBySource = require './in-collection-by-source'

  { permit } = require '../../models/group/permissionset.coffee'

  helpers = require 'bongo/lib/model/find-via-collection'

  { Inflector } = require 'bongo'

  getCollection = (konstructor, group) ->
    db = konstructor.getClient()
    return db.collection getCollectionName konstructor, group

  getCollectionName = (konstructor, group) ->
    { name } = konstructor
    mainCollectionName = Inflector(name).decapitalize().pluralize()
    collectionName = "#{mainCollectionName}"
    collectionName += "__#{group.replace /-/g, '_'}"  if group?
    return collectionName

  getCollectionByClient = (konstructor, client) ->
    { group } = client.context
    getCollection konstructor, group

  getCollection:(group) ->
    getCollection @constructor, group ? @group

  @getCollectionName = (group) ->
    getCollectionName this, group
    # mainCollectionName = Inflector(@name).decapitalize().pluralize()
    # return "#{mainCollectionName}__#{group.replace /-/g, '_'}"

  @drop$ = permit 'drop collection',
    success:(client, callback) ->
      collection = getCollectionByClient this, client
      helpers.drop.call this, collection, callback
      return this

  @one$ = permit 'query collection',
    success:(client, uniqueSelector, options, callback) ->
      collection = getCollectionByClient this, client
      helpers.one.call this, collection, uniqueSelector, options, callback
      return this

  @all$ = permit 'query collection',
    success:(client, selector, callback) ->
      collection = getCollectionByClient this, client
      helpers.all.call this, collection, selector, callback
      return this

  @remove$ = permit 'query collection',
    success:(client, selector, callback) ->
      collection = getCollectionByClient this, client
      helpers.remove.call this, collection, selector, callback
      return this

  @count$ = permit 'query collection',
    success:(client, selector, callback) ->
      collection = getCollectionByClient this, client
      helpers.count.call this, collection, selector, callback
      return this

  @some$ = permit 'query collection',
    success:(client, selector, options, callback) ->
      collection = getCollectionByClient this, client
      console.log { collection }
      helpers.some.call this, collection, selector, options, callback
      return this

  @someData$ = permit 'query collection',
    success:(client, selector, fields, options, callback) ->
      collection = getCollectionByClient this, client
      helpers.someData.call this, collection, selector, fields, options, callback
      return this

  @cursor$ = permit 'query collection',
    success:(client, selector, options, callback) ->
      collection = getCollectionByClient this, client
      helpers.cursor.call this, collection, selector, options, callback

  @each$ = permit 'query collection',
    success:(client, selector, fields, options, callback) ->
      collection = getCollectionByClient this, client
      helpers.each.call this, collection, selector, fields, options, callback

  save: (client, callback) ->
    [callback, client] = [client, callback]  unless callback
    { save_0_ } = require 'bongo/lib/model/save'
    model = this
    model.applyDefaults(model.isRoot_)
    collection =
      if client then getCollectionByClient @constructor, client
      else @constructor.getCollectionByClient()
    model.validate save_0_.bind model, callback, collection
    model

  save$: permit 'create documents',
    success:(client, callback) -> @save callback
