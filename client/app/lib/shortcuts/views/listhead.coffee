kd = require 'kd'

module.exports =

class ShortcutsListHead extends kd.View

  constructor: (options={}, data) ->

    options.cssClass = 'list-head'

    super options, data

  viewAppended: ->

    @setPartial """
      <div class=description>#{@getOptions().description}</div>
      <div class=shortcuts-list>
        <div class=row>
          <div class=col><span>Description</span></div>
          <div class=col><span>Binding</span></div>
          <div class=col><span>Enabled</span></div>
        </div>
      </div>
    """
