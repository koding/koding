kd               = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView


module.exports = class EmbedBoxLinkViewTitle extends KDCustomHTMLView

  constructor: (options = {}, data) ->

    options.cssClass   = kd.utils.curry 'title', options.cssClass
    options.tagName    = 'a'
    options.attributes =
      href             : data.link_url
      target           : '_blank'

    super options, data

    @updatePartial @getTitle()


  getTitle: ->

    { link_embed, title, link_url } = @getData()
    return link_embed?.title or title or link_url
