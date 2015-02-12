class EmbedBoxLinkDisplayView extends KDView

  constructor:(options={}, data)->
    options.cssClass = KD.utils.curry 'embed-link-view clearfix', options.cssClass
    super options, data

    if data?.link_embed?.images?[0]?
      @embedImage = new EmbedBoxLinkViewImage
        cssClass : 'preview-image'
        delegate : this
      ,data

    @embedContent = new EmbedBoxLinkViewContent
      cssClass  : 'preview-text'
      delegate  : this
    , data

  viewAppended : ->
    @addSubView @embedImage if @embedImage
    @addSubView @embedContent
