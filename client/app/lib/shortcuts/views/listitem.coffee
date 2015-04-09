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

    self = this

    toggle = new kd.View
      cssClass : 'col'
      tagName  : 'div'
      partial  : renderToggle enabled : @model.enabled
      click    : (e) ->
        enabled = if _.isBoolean e then e else not self._enabled
        @updatePartial renderToggle enabled: (self._enabled = enabled)
        self.emit 'StateChanged', @id

    description = new kd.View
      cssClass : 'col'
      partial  : _.escape @model.description

    binding = new kd.View
      cssClass : 'col'
      partial  : present _.first @model.binding
      click    : => @emit 'BindingSelected', @id

    @addSubView toggle
    @addSubView description
    @addSubView binding

    @on 'Synced', (model) ->
      toggle.click model.enabled
      binding.updatePartial present _.first model.binding

    @once 'KDObjectWillBeDestroyed', => @off 'Synced'
