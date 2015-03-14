kd = require 'kd'

module.exports =

class ShortcutsListHead extends kd.View

  constructor: (options={}, data) ->

    options.cssClass = 'list-head'

    super options, data

  viewAppended: ->

    @setPartial "<div>#{@getOptions().description}</div>"
