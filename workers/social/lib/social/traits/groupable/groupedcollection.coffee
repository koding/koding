helpers = require 'bongo/lib/model/find-via-collection'

{ Inflector } = require 'bongo'

module.exports = class GroupedCollection

  getCollection = require './get-collection'

  constructor:(@source, @konstructor) ->

  one:(uniqueSelector, options, callback) ->
    collection = getCollection @konstructor, @source.group
    helpers.one.call @konstructor, collection, uniqueSelector, options, callback

  all:(selector, callback) ->
    collection = getCollection @konstructor, @source.group
    helpers.all.call @konstructor, collection, selector, callback

  remove:(selector, callback) ->
    collection = getCollection @konstructor, @source.group
    helpers.remove.call @konstructor, collection, selector, callback

  count:(selector, callback) ->
    collection = getCollection @konstructor, @source.group
    helpers.count.call @konstructor, collection, selector, callback

  some:(selector, options, callback) ->
    collection = getCollection @konstructor, @source.group
    helpers.some.call @konstructor, collection, selector, options, callback

  someData:(selector, fields, options, callback) ->
    collection = getCollection @konstructor, @source.group
    helpers.someData.call @konstructor, collection, selector, fields, options, callback

  cursor:(selector, options, callback) ->
    collection = getCollection @konstructor, @source.group
    helpers.cursor.call @konstructor, collection, selector, options, callback

  each:(selector, fields, options, callback) ->
    collection = getCollection @konstructor, @source.group
    helpers.each.call @konstructor, collection, selector, fields, options, callback
