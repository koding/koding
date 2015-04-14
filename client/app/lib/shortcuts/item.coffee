kd = require 'kd'
_  = require 'lodash'
present = require './present-binding'
facade = require('./actions-facade')
EventType = require './event-type'

module.exports =

class Item extends kd.View

  constructor: (options={}, @model) ->

    @_enabled = @model.enabled
    @_handlers = null

    super _.extend
      cssClass: 'row'
    , options


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
      partial  : present _.first @model.binding

    toggleClickHandler = (e, silent=no) =>
      @_enabled = if _.isBoolean e then e else not @_enabled
      if @_enabled then toggle.setClass 'enabled' else toggle.unsetClass 'enabled'
      unless silent
        @emit 'ShortcutItemToggled', @_enabled

    bindingClickHandler = =>
      @setClass 'active'
      binding.updatePartial ''
      @emit EventType.Item.SELECTED,
        (res) =>
          partial = if res then present res else present _.first @model.binding
          binding.updatePartial partial
          @unsetClass 'active'

    changeHandler = (model) ->
      toggle.click model.enabled, yes
      # XXX: do not update binding if recording
      #binding.updatePartial present _.first model.binding

    destroyHandler = =>
      @off EventType.Facade.CHANGED, changeHandler
      toggle.off  'click', toggleClickHandler
      binding.off 'click', bindingClickHandler
      _.each EventType.Item, (type) =>
        @off type, @_handlers[type]
        @_handlers[type] = null
      @_handlers = null

    toggle.on  'click', toggleClickHandler
    binding.on 'click', bindingClickHandler

    @on EventType.Facade.CHANGED, changeHandler
    @once 'KDObjectWillBeDestroyed', destroyHandler

    @_handlers = {}
    _.each EventType.Item, (type) =>
      @_handlers[type] = facade.createHandler type, this
      @on type, @_handlers[type]

    @addSubView toggle
    @addSubView description
    @addSubView binding
