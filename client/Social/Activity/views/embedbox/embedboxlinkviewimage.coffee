class EmbedBoxLinkViewImage extends KDView

  constructor:(options={}, data)->
    super options, data

    oembed = @getData().link_embed
    @imageLink    = @utils.proxifyUrl(oembed.images?[0]?.url, width: 100, height: 100, crop: yes)
    altSuffix     = if oembed.author_name then " by #{oembed.author_name}" else ''
    @imageAltText = oembed.title + altSuffix

    @imageView = new KDCustomHTMLView
      tagName      : 'img'
      cssClass      : 'thumb'
      bind         : 'error'
      error        : @bound 'hide'
      attributes   :
        src        : @imageLink
        alt        : @imageAltText
        title      : @imageAltText

  # this will get called from the image-switch click events to update the preview
  # images when browsing the available embed links
  setSrc: (src) ->
    @imageView.getElement().src = src

  viewAppended:->
    JView::viewAppended.call this

    {link_embed} = @getData()

    return  unless link_embed?

    if link_embed.object?.type is 'video'
      @videoPopup = new VideoPopup
        delegate : @imageView
        title    : link_embed.title or 'Untitled Video'
        thumb    : link_embed.images?[0]?.url
      , link_embed.object.html

  pistachio:->
    """
    <a class="preview_link" target="_blank" href="#{@getData().link_url or @getData().link_embed?.url}">
      {{> @imageView}}
    </a>
    """