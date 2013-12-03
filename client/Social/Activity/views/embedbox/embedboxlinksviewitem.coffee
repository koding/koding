class EmbedBoxLinksViewItem extends KDListItemView

  constructor:(options={}, data)->

    options = @utils.extend {}, options,
      cssClass    : 'embed-link-item'
      tooltip     :
        title     : data.url
        placement : 'above'
        offset    : 3
        delayIn   : 300
        html      : yes
        animate   : yes

    super options,data

  partial:->
    # visible link shortening here
    # http://www.foo.bar/baz -> www.foo.bar
    linkUrlShort = @getData().url
      .replace(@utils.webProtocolRegExp, '')
      .replace(/\/.*/, '')

    """
    <div class="embed-link-wrapper">
      #{ linkUrlShort }
    </div>
    """