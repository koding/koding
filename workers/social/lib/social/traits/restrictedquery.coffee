module.exports = class RestrictedQuery

  { permit } = require '../models/group/permissionset'

  makeGroupSelector = (group) ->
    if Array.isArray group then $in: group else group


  @update$ = permit 'update collection',
    success:(client, selector, operation, options, callback) ->
      selector.group = makeGroupSelector client.context.group
      @update selector, operation, options, callback

  @assure$ = permit 'assure collection',
    success:(client, selectorOrInitializer, callback) ->
      { group } = client.context
      callback {
        message: 'Invalid group!'
      }  if Array.isArray group
      selectorOrInitializer.group = group
      @assure selectorOrInitializer, callback

  @one$ = permit 'query collection',
    success:(client, uniqueSelector, options, callback) ->
      # TODO: this needs more security?
      uniqueSelector.group = makeGroupSelector client.context.group
      @one uniqueSelector, options, callback

  @all$ = permit 'query collection',
    success:(client, selector, callback) ->
      selector.group = client.context.group
      @all selector, callback

  @remove$ = permit 'remove documents from collection',
    success:(client, selector, callback) ->
      selector.group = client.context.group
      @remove selector, callback

  @removeById$ = permit 'remove documents from collection',
    success:(client, _id, callback) ->
      selector = {
        _id, group : makeGroupSelector client.context.group
      }
      @remove selector, callback

  @count$ = permit 'query collection',
    success:(client, selector, callback) ->
      [callback, selector] = [selector, callback]  unless callback
      selector ?= {}
      selector.group = makeGroupSelector client.context.group
      @count selector, callback

  @some$ = permit 'query collection',
    success:(client, selector, options, callback) ->
      selector.group = makeGroupSelector client.context.group
      @some selector, options, callback

  @someData$ = permit 'query collection',
    success:(client, selector, options, fields, callback) ->
      selector.group = makeGroupSelector client.context.group
      @someData selector, options, fields, callback

  @cursor$ = permit 'query collection',
    success:(client, selector, options, callback) ->
      selector.group = makeGroupSelector client.context.group
      @cursor selector, options, callback

  @each$ = permit 'query collection',
    success:(client, selector, fields, options, callback) ->
      selector.group = makeGroupSelector client.context.group
      @each selector, fields, options, callback

  @hose$ = permit 'query collection',
    success:(client, selector, rest...) ->
      selector.group = makeGroupSelector client.context.group
      @someData selector, rest...

  @teasers$ = permit 'query collection',
    success:(client, selector, options, callback) ->
      selector.group = makeGroupSelector client.context.group
      @teasers selector, options, callback
