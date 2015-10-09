kd = require 'kd'

module.exports = class AdminSubTabHandleView extends kd.TabHandleView

  constructor: ->

    super

    @path = @getOptions().pane.getOptions().route


  click: (event) ->

    kd.utils.stopDOMEvent event
    kd.singletons.router.handleRoute @path

    return no


  partial: -> "<a href='#{@path}'>#{@getOptions().title}</a>"
