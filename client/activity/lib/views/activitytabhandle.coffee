kd = require 'kd'
KDTabHandleView = kd.TabHandleView
CustomLinkView = require 'app/customlinkview'


module.exports = class ActivityTabHandle extends KDTabHandleView

  constructor: (options, data) ->
    options.cssClass = kd.utils.curry 'filter', options.cssClass
    super options, data


  partial: -> ''

  viewAppended: ->
    { pane } = @getOptions()
    { name: title, route: href } = pane.getOptions()

    @setAttribute "testpath","ActivityTabHandle-#{href}"

    @addSubView new CustomLinkView { title, href }
