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
          <div><span>Description</span></div>
          <div><span>Binding</span></div>
          <div><span>Enabled</span></div>
        </div>
      </div>
    """
