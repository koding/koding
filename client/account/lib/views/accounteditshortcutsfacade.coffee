_         = require 'lodash'
recorder  = require 'record-shortcuts'
EventType = require './accounteditshortcutseventtype'
kd        = require 'kd'

running = no
entities = {}

getShortcuts = -> kd.singletons.shortcuts

# Handles Item.SELECTED events.
#
selectHandler = (cb) ->

  # Start a new recording session.
  recorder.start()
    .on 'end', (res) =>
      # A valid shortcut can't have less than 2 characters, so pass void to
      # callback.
      return cb()  if res.length < 2

      # This will eventually dispatch a shortcuts#change when appstorage is synced-up
      # with internal representation.
      getShortcuts()
        .update @model.collection, @model.name,
          binding: [ res.join '+' ]

      # Let Item change itself before appstorage syncup.
      # This is more or less equivalent to dispatching Facade.CHANGED.
      cb res

    # Pressing ESC will cancel out current recording session, in that case
    # recorder will return void.
    .on 'cancel', cb


# Handles Item.TOGGLED events.
#
toggleHandler = (enabled) ->

  # This will eventually dispatch a shortcuts#change when appstorage is synced-up
  # with internal representation.
  getShortcuts()
    .update @model.collection, @model.name,
      options: { enabled }


# Handles shortcuts#change events.
#
changeHandler = (collection, model) ->

  key = "#{collection.name}$#{model.name}"
  entity = entities[key]
  # Facade.CHANGED is fired for only corresponding Item of the changed keyconfig.Model.
  entity.emit EventType.Facade.CHANGED, model

  # For every change we calculate collisions again.
  dups = getShortcuts().getCollisionsFlat collection.name

  # And dispatch Facade.DUP on each Item instances.
  collection.each (model) ->
    return  if model.options.hidden is yes
    key = "#{collection.name}$#{model.name}"
    entity = entities[key]
    entity.emit EventType.Facade.DUP, _.includes dups, model.name


# Destroys facade; stop listening for shortcuts change, and cleans up saved Item refs.
#
exports.dispose = ->

  recorder.cancel()
  getShortcuts().removeListener 'change', changeHandler
  entities = {}
  running = no


# Returns a user action handler for the given Item event type and scope.
#
# * Item.SELECTED is triggered upon user clicks on a binding.
# * Item.TOGGLED is triggered upon user clicks on checkbox.
#
exports.createHandler = (type, ctx) ->

  if not running
    running = yes
    # Start listening for shortcut changes.
    getShortcuts().on 'change', changeHandler

  # Save given item entity, so we can dispatch events directly on it.
  key = "#{ctx.model.collection}$#{ctx.model.name}"
  entities[key] = ctx  unless _.has entities, key

  switch type
    when EventType.Item.SELECTED
      return _.bind selectHandler, ctx
    when EventType.Item.TOGGLED
      return _.bind toggleHandler, ctx
