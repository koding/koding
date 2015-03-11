kd                          = require 'kd'
KDView                      = kd.View
EmbedBoxLinkViewDescription = require './embedboxlinkviewdescription'
EmbedBoxLinkViewProvider    = require './embedboxlinkviewprovider'
EmbedBoxLinkViewTitle       = require './embedboxlinkviewtitle'


module.exports = class EmbedBoxLinkViewContent extends KDView

  constructor: (options = {}, data) ->

    super options, data

    @addSubView @embedTitle       = new EmbedBoxLinkViewTitle {}, data
    @addSubView @embedDescription = new EmbedBoxLinkViewDescription {}, data
    @addSubView @embedProvider    = new EmbedBoxLinkViewProvider {}, data
