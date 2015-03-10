kd                          = require 'kd'
KDView                      = kd.View
EmbedBoxLinkViewDescription = require './embedboxlinkviewdescription'
EmbedBoxLinkViewProvider    = require './embedboxlinkviewprovider'
EmbedBoxLinkViewTitle       = require './embedboxlinkviewtitle'


module.exports = class EmbedBoxLinkViewContent extends KDView

  constructor:(options={},data)->
    super options, data

    contentOptions =
      tagName    : 'a'
      cssClass   : 'preview-text-link'
      attributes :
        href     : data.link_url
        target   : '_blank'

    @embedTitle = new EmbedBoxLinkViewTitle contentOptions, data

    @embedProvider = new EmbedBoxLinkViewProvider cssClass: 'provider-info', data

    @embedDescription = new EmbedBoxLinkViewDescription contentOptions, data

  viewAppended : ->
    @addSubView @embedTitle
    @addSubView @embedDescription
    @addSubView @embedProvider


