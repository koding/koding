kd               = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView
EmbedBox         = require 'activity/views/embedbox'
getEmbedType     = require 'app/util/getEmbedType'

hasEmbed = (data) -> data.link? and Object.keys(data.link).length > 0

module.exports = updateEmbedBoxMixin = ->

  data     = @getData()
  embedBox = null
  if hasEmbed data
    { link_embed } = data.link
    embedType      = (getEmbedType link_embed?.type) or 'link'
    isEmptyLink    = embedType is 'link' and not link_embed?.description

    embedBox = if isEmptyLink
    then new KDCustomHTMLView
    else new EmbedBox @embedOptions, data.link

  else embedBox = new KDCustomHTMLView

  @embedBoxWrapper.destroySubViews()
  @embedBoxWrapper.addSubView embedBox
  @emit 'EmbedBoxUpdated'

