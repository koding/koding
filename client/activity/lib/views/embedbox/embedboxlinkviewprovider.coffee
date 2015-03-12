kd               = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView

module.exports = class EmbedBoxLinkViewProvider extends KDCustomHTMLView

  constructor: (options = {}, data = {}) ->

    options.cssClass   = kd.utils.curry 'provider-info', options.cssClass
    options.tagName    = 'a'
    options.attributes =
      href             : data.link_url
      target           : '_blank'

    super options, data

    @hide()  unless @getData().link_embed?.provider_name?

    { link_embed, provider_name } = @getData()

    link_embed       or= {}
    provider_name    or= link_embed.provider_name    or ''

    @updatePartial "<strong>#{provider_name}</strong>"
