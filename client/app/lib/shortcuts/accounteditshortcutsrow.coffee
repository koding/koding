kd                 = require 'kd'
_                  = require 'lodash'
facade             = require('./accounteditshortcutsfacade')
EventType          = require './accounteditshortcutseventtype'
recorder           = require 'record-shortcuts'
{ presentBinding } = require 'app/shortcutscontroller'

module.exports =

class AccountEditShortcutsRow extends kd.View

  # Class name for columns.
  COL_CLASS_NAME = 'col'

  # Class name to set for currently recording item.
  ENABLED_CLASS_NAME = 'enabled'

  # Class name to set for currently recording item.
  ACTIVE_CLASS_NAME = 'active'

  # Class name to set for duplicate/colliding items.
  DUP_CLASS_NAME = 'collides'

  # Class name that we use to catch cancel click.
  CANCEL_CLASS_NAME = 'cancel'

  # The maximum description string length.
  DESCRIPTION_TRUNC_LEN = 100

  # The maximum description string length for a single line.
  SINGLE_LINE_LEN = 50

  # The separator pattern to truncate to.
  DESCRIPTION_TRUNC_SEP = ' '

  CLICK = 'click'

  CLASS_NAME = 'row'

  TOGGLE_PARTIAL = '<div class=toggle><span class=icon>'

  BINDING_ACTIVE_PARTIAL = '<span class=cancel>'

  constructor: (options, data) ->

    @model = data
    @_enabled = @model.enabled
    @_binding = _.first @model.binding
    @_handlers = null
    @_active = no

    @_dup = options.dup
    delete options.dup

    super _.extend { cssClass: CLASS_NAME, options }

    if @_dup then @setClass DUP_CLASS_NAME


  viewAppended: ->

    toggle = new kd.View
      cssClass : COL_CLASS_NAME
      partial  : TOGGLE_PARTIAL

    if @model.enabled then toggle.setClass ENABLED_CLASS_NAME

    descriptionText = _.escape @model.description

    if descriptionText.length > SINGLE_LINE_LEN
      @setClass 'multi-line-row'

    description = new kd.View
      cssClass : COL_CLASS_NAME
      partial  : _.truncate descriptionText, {
        separator: DESCRIPTION_TRUNC_SEP,
        length: DESCRIPTION_TRUNC_LEN
      }

    if descriptionText.length > DESCRIPTION_TRUNC_LEN
      description.domElement.attr 'title', descriptionText

    binding = new kd.View
      cssClass : COL_CLASS_NAME
      partial  : presentBinding @_binding

    # Handles checkbox clicks.
    #
    # Pass silent to trigger this explicitly, otherwise you will get an inf. loop.
    #
    toggleClickHandler = (e, silent = no) =>
      e.preventDefault?()
      e.stopPropagation?()
      @_enabled = if _.isBoolean e then e else not @_enabled
      if @_enabled then toggle.setClass ENABLED_CLASS_NAME else toggle.unsetClass ENABLED_CLASS_NAME
      unless silent
        @emit EventType.Item.TOGGLED, @_enabled

    # Handles dom click events.
    #
    clickHandler = (e) =>
      if @_active
        recorder.cancel()  if e.target.className is CANCEL_CLASS_NAME
        return

      @setClass ACTIVE_CLASS_NAME
      @unsetClass DUP_CLASS_NAME
      @_active = yes
      binding.updatePartial BINDING_ACTIVE_PARTIAL

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
