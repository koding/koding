kd = require 'kd'
_  = require 'lodash'
present = require '../presenters/binding'

renderToggle = _.template """
  <div class="toggle <% if(enabled) { %>enabled<% } %>">
  <span class=icon>
"""

module.exports =

class Item extends kd.View

  constructor: (options={}, @model) ->

    @_enabled = @model.enabled

    super _.extend
      cssClass: 'row'
    , options


  viewAppended: ->

    toggle = new kd.View
      cssClass : 'col'
      tagName  : 'div'
      partial  : renderToggle enabled : @model.enabled

    description = new kd.View
      cssClass : 'col'
      partial  : _.escape @model.description

    binding = new kd.View
      cssClass : 'col'
      partial  : present _.first @model.binding

    toggleClickHandler = (e) =>
      enabled = if _.isBoolean e then e else not @_enabled
      toggle.updatePartial renderToggle enabled: (@_enabled = enabled)
      @emit 'Toggled', @_enabled

    bindingClickHandler = =>
      @setClass 'active'
      binding.updatePartial ''
      @emit 'Selected',
        (res) =>
          partial = if res then present res else present _.first @model.binding
          binding.updatePartial partial
          @unsetClass 'active'

    syncHandler = (model) ->
      toggle.click model.enabled
      #binding.updatePartial present _.first model.binding

    destroyHandler = =>
      @off        'Synced' , syncHandler
      toggle.off  'click'  , toggleClickHandler
      binding.off 'click'  , bindingClickHandler

    toggle.on  'click'                   , toggleClickHandler
    binding.on 'click'                   , bindingClickHandler
    @on        'Synced'                  , syncHandler
    @once      'KDObjectWillBeDestroyed' , destroyHandler

    @addSubView toggle
    @addSubView description
    @addSubView binding
