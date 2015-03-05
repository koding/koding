kd = require 'kd'
ReplyInputWidget = require './replyinputwidget'
Encoder = require 'htmlencode'

module.exports = class ReplyInputEditWidget extends ReplyInputWidget

  constructor: (options = {}, data) ->

    options.cssClass        = kd.utils.curry 'edit-widget', options.cssClass
    options.destroyOnSubmit = yes

    super options, data

    @unsetClass 'reply-input-widget'


  viewAppended: ->

    {body, link} = @getData()

    @input.setValue Encoder.htmlDecode body
    @embedBox.loadEmbed link.link_url  if link

    @addSubView @embedBox

