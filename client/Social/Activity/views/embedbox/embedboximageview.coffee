class EmbedBoxImageView extends JView

  constructor:(options={}, data)->
    super data.link_options, data

    oembed = @getData().link_embed

    srcUrl = @utils.proxifyUrl oembed.images?[0]?.url, width: 728, height: 368, grow: yes, crop: yes

    @image  = new KDCustomHTMLView
      tagName     : 'img'
      attributes  :
        src       : srcUrl
        title     : oembed.title or ''
        width     : "100%"

    @setClass "embed-image-view"

  pistachio:->
    { link_url } = @getData()
    """
    <a href="#{link_url or '#'}" target="_blank">
      {{> @image}}
    </a>
    """
