class EmbedBoxImageView extends JView

  constructor:(options={}, data)->
    super data.link_options, data

    oembed = @getData().link_embed

    srcUrl = @utils.proxifyUrl oembed.images?[0]?.url, width: 341, height: 291

    @image  = new KDCustomHTMLView
      tagName     : 'img'
      attributes  :
        src       : srcUrl
        title     : oembed.title or ''

  pistachio:->
    { link_url } = @getData()
    """
    <div class="embed embed-image-view custom-image clearfix">
      <a href="#{link_url or '#'}" target="_blank">
        {{> @image}}
      </a>
      <div class="details">
        {strong{ #(link_embed.provider_name)}}
        <a href="#{link_url}" target="_blank" class="url">#{link_url}</span>
      </div>
    </div>
    """
