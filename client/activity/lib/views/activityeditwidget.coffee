kd                  = require 'kd'
ActivityInputWidget = require './activityinputwidget'
Encoder             = require 'htmlencode'


module.exports = class ActivityEditWidget extends ActivityInputWidget

  constructor: (options = {}, data) ->

    options.cssClass        = kd.utils.curry 'edit-widget', options.cssClass
    options.destroyOnSubmit = yes

    super options, data

  viewAppended: ->

    data         = @getData()
    {body, link} = data

    @addSubView @input
    @addSubView @embedBox

    @input.setValue Encoder.htmlDecode body
    @input.emit 'BeingEdited', link?.link_url
