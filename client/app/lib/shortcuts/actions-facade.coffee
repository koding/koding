_ = require 'lodash'
recorder = require 'record-shortcuts'
EventType = require './event-type'
kd = require 'kd'

running = no
entities = {}

getShortcuts = -> kd.singletons.shortcuts


selectHandler = (cb) ->

  recorder.start()
    .on 'end', (res) =>
      if res.length < 2 then return cb()
      getShortcuts()
        .update @model.collection, @model.name,
          binding: [ res.join '+' ]
      cb res
    .on 'cancel', cb


toggleHandler = (enabled) ->

  getShortcuts()
    .update @model.collection, @model.name,
      options: enabled: enabled


changeHandler = (collection, model) ->

  key = "#{collection.name}$#{model.name}"
  entity = entities[key]
  entity.emit EventType.Facade.CHANGED, model

  dups = getShortcuts().getCollisionsFlat collection.name

  collection.each (model) ->
    return  if model.options.hidden is yes
    key = "#{collection.name}$#{model.name}"
    entity = entities[key]
    entity.emit EventType.Facade.DUP, _.includes dups, model.name


exports.dispose = ->

  getShortcuts().removeListener 'change', changeHandler
  entities = {}
  running = no


exports.createHandler = (type, ctx) ->

  if not running
    running = yes
    getShortcuts().on 'change', changeHandler

  key = "#{ctx.model.collection}$#{ctx.model.name}"
  unless _.has entities, key then entities[key] = ctx

  switch type
    when EventType.Item.SELECTED
      return _.bind selectHandler, ctx
    when EventType.Item.TOGGLED
      return _.bind toggleHandler, ctx
