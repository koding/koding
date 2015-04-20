kd = require 'kd'
_  = require 'lodash'
facade = require('./accounteditshortcutsfacade')
EventType = require './accounteditshortcutseventtype'
globals = require 'globals'

# On Mac we display corresponding unicode chars for the following keys.
# See: http://macbiblioblog.blogspot.nl/2005/05/special-key-symbols.html
#
MAC_UNICODE =
  shift       : '&#x21E7;'
  command     : '&#x2318;'
  alt         : '&#x2325;'
  ctrl        : '&#x2303'
  tab         : '&#x21e5'
  'caps lock' : '&#x21ea'
  space       : '&#x2423'
  enter       : '&#x23ce'
  backspace   : '&#x232b'
  home        : '&#x21f1'
  end         : '&#x21f2'
  'page up'   : '&#x21de'
  'page down' : '&#x21df'
  left        : '&#x2190'
  up          : '&#x2191'
  right       : '&#x2192'
  down        : '&#x2193'
  esc         : '&#x238b'
  'num lock'  : '&#x21ed'

# Determines the text conversion method to use when displaying bindings.
convertCase = _.capitalize

# Generates a compiled template function for rendering bindings.
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

  # Class name for columns.
  COL_CLASS_NAME = 'col'

  # Class name to set for currently recording item.
  ENABLED_CLASS_NAME = 'enabled'

  # Class name to set for currently recording item.
  ACTIVE_CLASS_NAME = 'active'

  # Class name to set for duplicate/colliding items.
  DUP_CLASS_NAME = 'collides'

  # The maximum description string length.
  DESCRIPTION_TRUNC_LEN = 30

  # The separator pattern to truncate to.
  DESCRIPTION_TRUNC_SEP = ' '

  CLICK = 'click'

  CLASS_NAME = 'row'

  TOGGLE_PARTIAL = '<div class=toggle><span class=icon>'

  constructor: (options, data) ->

    @model = data
    @_enabled = @model.enabled
    @_binding = _.first @model.binding
    @_handlers = null
    @_active = no

    @_dup = options.dup
    delete options.dup

    super _.extend cssClass: CLASS_NAME, options

    if @_dup then @setClass DUP_CLASS_NAME


  viewAppended: ->

    toggle = new kd.View
      cssClass : COL_CLASS_NAME
      partial  : TOGGLE_PARTIAL

    if @model.enabled then toggle.setClass ENABLED_CLASS_NAME

    descriptionText = _.escape @model.description

    description = new kd.View
      cssClass : COL_CLASS_NAME
      partial  : _.trunc descriptionText, separator: DESCRIPTION_TRUNC_SEP, length: DESCRIPTION_TRUNC_LEN

    if descriptionText.length > DESCRIPTION_TRUNC_LEN
      description.domElement.attr 'title', descriptionText

    binding = new kd.View
      cssClass : COL_CLASS_NAME
      partial  : presentBinding @_binding

    # Handles checkbox clicks.
    #
    # Pass silent to trigger this explicitly, otherwise you will get an inf. loop.
    #
    toggleClickHandler = (e, silent=no) =>
      e.preventDefault?()
      e.stopPropagation?()
      @_enabled = if _.isBoolean e then e else not @_enabled
      if @_enabled then toggle.setClass ENABLED_CLASS_NAME else toggle.unsetClass ENABLED_CLASS_NAME
      unless silent
        @emit EventType.Item.TOGGLED, @_enabled

    # Handles dom click events.
    #
    clickHandler = =>
      return  if @_active

      @setClass ACTIVE_CLASS_NAME
      @unsetClass DUP_CLASS_NAME
      @_active = yes
      binding.updatePartial ''

      # Start a recording session.
      @emit EventType.Item.SELECTED,
        # Following will be called upon a recording session is finished.
        # If res is not void then it means we have successfully changed a binding,
        # thus eventually we will get a Facade.CHANGED.
        # Otherwise we set the previous binding.
        (res) =>
          @_active = no
          if res
            partial = presentBinding res
          else
            partial = presentBinding @_binding
            dupHandler @_dup
          binding.updatePartial partial
          @unsetClass ACTIVE_CLASS_NAME

    # Handles Facade.CHANGED, which is only fired upon app storage is synced-up
    # with internal representation.
    #
    # Beware that returned model is not a json representation, but the keyconfig.Model itself.
    #
    changeHandler = (model) ->
      { shortcuts } = kd.singletons
      @_binding = _.first shortcuts.getPlatformBinding model
      enabled = if model.options?.enabled is no then no else yes
      toggleClickHandler enabled, yes
      # Do not update binding while in a recording session.
      if not @_active
        binding.updatePartial presentBinding @_binding

    # Handles Facade.DUP, which is fired on every change made.
    # 
    # Passed value determines if this row's binding is colliding with some other binding or not.
    #
    dupHandler = (dup) =>
      @_dup = dup
      if dup
      then @setClass   DUP_CLASS_NAME
      else @unsetClass DUP_CLASS_NAME

    # Handles kd.Object#destroy event, cleans up the scene.
    #
    destroyHandler = =>
      @off EventType.Facade.CHANGED, changeHandler
      @off EventType.Facade.DUP, dupHandler
      @off CLICK, clickHandler
      toggle.off CLICK, toggleClickHandler
      _.each EventType.Item, (type) =>
        @off type, @_handlers[type]
        @_handlers[type] = null
      @_handlers = null

    # Add handlers for dom events.
    @on CLICK, clickHandler
    toggle.on CLICK, toggleClickHandler

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
