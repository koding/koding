kd = require 'kd'
KDView = kd.View
EmbedBoxImageView = require './embedbox/embedboximageview'
EmbedBoxLinkDisplayView = require './embedbox/embedboxlinkdisplayview'
EmbedBoxObjectView = require './embedbox/embedboxobjectview'
getEmbedType = require 'app/util/getEmbedType'

module.exports = class EmbedBox extends KDView
  constructor: (options = {}, data) ->
    options.cssClass = kd.utils.curry 'link-embed-box clearfix', options.cssClass
    super options, data

  viewAppended: ->
    return  unless data = @getData()

    embedType = (getEmbedType data?.link_embed?.type) or 'link'

    containerClass = switch embedType
      when 'image'  then EmbedBoxImageView
      when 'object' then EmbedBoxObjectView
      else               EmbedBoxLinkDisplayView

    embedOptions =
      cssClass: 'link-embed clearfix'
      delegate: this

    @addSubView new containerClass embedOptions, data


