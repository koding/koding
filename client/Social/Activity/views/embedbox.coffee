class EmbedBox extends KDView
  constructor: (options = {}, data) ->
    options.cssClass = KD.utils.curry 'link-embed-box', options.cssClass
    super options, data

  viewAppended: ->
    return  unless data = @getData()

    embedType = (@utils.getEmbedType data?.link_embed?.type) or 'link'

    if data?.link_embed?.media?.type is 'video'
      embedType = @utils.getEmbedType data.link_embed.media.type

    containerClass = switch embedType
      when 'image'  then EmbedBoxImageView
      when 'object' then EmbedBoxObjectView
      else               EmbedBoxLinkDisplayView

    embedOptions =
      cssClass: 'link-embed clearfix'
      delegate: this

    @addSubView new containerClass embedOptions, data
