kd = require 'kd'
_  = require 'lodash'
facade = require('./accounteditshortcutsfacade')
EventType = require './accounteditshortcutseventtype'
globals = require 'globals'

# Determines class name to set for duplicate/colliding items.
DUP_CLASS_NAME = 'collides'

# On Mac we display corresponding unicode chars for the following keys.
MAC_UNICODE =
  shift   : '&#x21E7;'
  command : '&#x2318;'
  alt     : '&#x2325;'
  ctrl    : '^'

# Determines the text conversion method to use when displaying bindings.
convertCase = _.capitalize

# Generates a compiled template function.
renderBinding =
  _.template '<% _.forEach(keys, function (key) { %><span><%= key %></span><% }) %>'

# Returns a html string presentation for the given binding array or string.
#
presentBinding = (keys) ->

  if _.isString keys then keys = keys.split '+'

  renderBinding keys:
    if globals.os isnt 'mac'
    then _.map keys, (value) -> convertCase value
    else _.map keys, (value) -> MAC_UNICODE[value] or convertCase value


module.exports =

class AccountEditShortcutsRow extends kd.View

  constructor: (options, data) ->

    @model = data
    @_enabled = @model.enabled
    @_handlers = null

    dup = options.dup
    delete options.dup

    super _.extend cssClass: 'row', options

    if dup then @setClass DUP_CLASS_NAME


  viewAppended: ->

    toggle = new kd.View
      cssClass : 'col'
      tagName  : 'div'
      partial: '<div class=toggle><span class=icon>'

    if @model.enabled then toggle.setClass 'enabled'

    description = new kd.View
      cssClass : 'col'
      partial  : _.escape @model.description

    binding = new kd.View
      cssClass : 'col'
      partial  : presentBinding _.first @model.binding

    # Handles checkbox clicks.
    #
    # Pass silent to trigger this explicitly, otherwise you will get an inf. loop.
    #
    toggleClickHandler = (e, silent=no) =>
      @_enabled = if _.isBoolean e then e else not @_enabled
      if @_enabled then toggle.setClass 'enabled' else toggle.unsetClass 'enabled'
      unless silent
        @emit EventType.Item.TOGGLED, @_enabled

    # Handles dom click events on binding cell.
    #
    bindingClickHandler = =>
      # Cleanup displayed binding.
      @setClass 'active'
      binding.updatePartial ''
      # Start a recording session.
      @emit EventType.Item.SELECTED,
        # Following will be called upon a recording session is finished.
        # If res is not void then it means we have successfully changed a binding,
        # thus eventually we will get a Facade.CHANGED.
        # Otherwise we set the previous binding.
        (res) =>
          partial = if res then presentBinding res else presentBinding _.first @model.binding
          binding.updatePartial partial
          @unsetClass 'active'

    # Handles Facade.CHANGED, which is only fired upon app storage is synced-up
    # with internal representation.
    #
    # Beware that returned model is not a json representation, but the keyconfig.Model itself.
    #
    changeHandler = (model) ->
      toggle.click model.enabled, yes
      # XXX: do not update binding while recording
      { shortcuts } = kd.singletons
      binding.updatePartial presentBinding _.first shortcuts.getPlatformBinding model

    # Handles Facade.DUP, which is fired on every change made.
    # 
    # Passed value determines if this row's binding is colliding with some other binding or not.
    #
    dupHandler = (dup) =>
      if dup
      then @setClass   DUP_CLASS_NAME
      else @unsetClass DUP_CLASS_NAME

    # Handles kd.Object#destroy event, cleans up the scene.
    #
    destroyHandler = =>
      @off EventType.Facade.CHANGED, changeHandler
      @off EventType.Facade.DUP, dupHandler
      toggle.off  'click', toggleClickHandler
      binding.off 'click', bindingClickHandler
      _.each EventType.Item, (type) =>
        @off type, @_handlers[type]
        @_handlers[type] = null
      @_handlers = null

    # Add handlers for dom events.
    toggle.on  'click', toggleClickHandler
    binding.on 'click', bindingClickHandler

    # Add handlers for facade events.
    @on EventType.Facade.CHANGED, changeHandler
    @on EventType.Facade.DUP, dupHandler

    # Add handlers for kd events.
    @once 'KDObjectWillBeDestroyed', destroyHandler

    # Add handlers for SELECTED and TOGGLED events which are going to be dispatched by facade.
    @_handlers = {}
    _.each EventType.Item, (type) =>
      @_handlers[type] = facade.createHandler type, this
      @on type, @_handlers[type]

    @addSubView toggle
    @addSubView description
    @addSubView binding
