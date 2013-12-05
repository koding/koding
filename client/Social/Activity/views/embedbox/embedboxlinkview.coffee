class EmbedBoxLinkView extends JView

  constructor:(options={}, data)->
    super options, data

    if data.link_embed?.images?[0]?
      @embedImage = new EmbedBoxLinkViewImage
        cssClass : 'preview-image'
        delegate : this
      , data
    else
      @embedImage = new KDCustomHTMLView 'hidden'

    @embedContent = new EmbedBoxLinkViewContent
      cssClass  : 'preview-text'
      delegate  : this
    , data

    @embedImageSwitch = new EmbedBoxLinkViewImageSwitch
      cssClass : 'preview-link-pager'
      delegate : this
    , data

  pistachio:->
    """
    <div class="embed embed-link-view custom-link">
      {{> @embedImageSwitch}}
      {{> @embedImage}}
      {{> @embedContent}}
    </div>
    """
