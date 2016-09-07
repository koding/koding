kd      = require 'kd'
KDView  = kd.View
Encoder = require 'htmlencode'


module.exports = class EmbedBoxLinkViewDescription extends KDView

  constructor: (options = {}, data = {}) ->

    options.cssClass   = kd.utils.curry 'description', options.cssClass
    options.tagName    = 'a'
    options.attributes =
      href             : data.link_url
      target           : '_blank'

    super options, data

    @updatePartial @getDescription()


  getDescription: ->

    value = @getData().link_embed?.description or @getData().description

    return '' unless value?
    return "#{Encoder.XSSEncode(value).substring 0, 128}..."
