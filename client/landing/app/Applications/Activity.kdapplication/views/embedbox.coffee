###
  Expected data structure:

    link :
      link_url                : String
      link_embed              : Object (oembed structure)
###

class EmbedBox extends KDView

  constructor:(options={}, data={})->

    @oembed     = data.link_embed or {}
    @url        = data.link_url or ''
    @cache      = []
    @imageIndex = 0
    @hasValidContent = no

    super options, data

    # top right corner either has the remove-embed button
    # or the report-button (to report malicious content)
    if @options.hasConfig
      @settingsButton = new KDButtonView
        cssClass    : 'hide-embed'
        icon        : yes
        iconOnly    : yes
        iconClass   : 'hide'
        title       : 'hide'
        callback    : @bound 'resetEmbedAndHide'
    else
      @settingsButton = new KDView

    @setClass 'link-embed-box'

    @embedLoader = new KDLoaderView
      cssClass      : 'embed-loader hidden'
      size          :
        width       : 30
      loaderOptions :
        color       : '#5f5f5f'
        shape       : 'spiral'
        diameter    : 30
        density     : 30
        range       : 0.4
        speed       : 1
        FPS         : 24

    @embedType  = data.link_embed?.object?.type or data.link_embed?.type or 'link'

    @embedLinks = new EmbedBoxLinksView
      cssClass : 'embed-links-container'
      delegate : this
    @embedLinks.hide()

    @embedContainer = new KDView options, data

    @hide()  unless data is {}

  viewAppended:->
    super()
    @setTemplate @pistachio()
    @template.update()

  loadImages:->
    do =>
      @utils.defer =>
        @$('img').each (i,element)->
          if $(element).attr 'data-src'
            $(element).attr 'src' : $(element).attr('data-src')
            $(element).removeAttr 'data-src'
          element

  addToCache:(item)-> @cache.push item  if item.url? and item not in @cache
  setImageIndex:(@imageIndex)->

  refreshEmbed:-> @populateEmbed @oembed, @url, {}

  resetEmbedAndHide:->
    @resetEmbed()
    @embedLinks.clearLinks()
    @hasValidContent = no
    @hide()

  # these resets only concern the currently displayed embed
  resetEmbed:->
    @oembed     = {}
    @url        = ''
    @imageIndex = 0

  getDataForSubmit:->
    return {}  if _.isEmpty @oembed

    data             = @oembed
    embedText        = @embedContainer.embedText
    data.title       = embedText?.embedTitle?.titleInput?.getValue() or ''
    data.description = embedText?.embedDescription?.descriptionInput?.getValue() or ''

    unless data.original_title?
      data.original_title = embedText?.embedTitle?.getOriginalValue() or ''

    unless data.original_description?
      data.original_description = embedText?.embedDescription?.getOriginalValue() or ''

    # remove unneded data
    delete data.original_url
    delete data.favicon_url
    delete data.place
    delete data.embeds
    delete data.cache_age
    delete data.event

    for image, i in data.images
      delete data.images[i]  if i isnt @imageIndex
    @imageIndex = 0

    for own key, field of data when _.isString(field)
      data[key] = field.replace(/&quot;/g, '"')

    return data

  getRichEmbedWhitelist:-> [] # add provider name here if we dont want to embed

  populateEmbed:(data={}, options={})->
    return  unless data

    @oembed = data
    @url    = data.url

    displayEmbedType=(embedType, data)=>
      @hasValidContent = yes

      embedOptions = _.extend {}, @options, {
        cssClass : 'link-embed clearfix'
        delegate : @
      }

      switch embedType
        when 'image'  then containerClass = EmbedBoxImageView
        when 'object' then containerClass = EmbedBoxObjectView
        else               containerClass = EmbedBoxLinkView

      @embedLinks.hide()
      @embedContainer = new containerClass embedOptions, data
      @embedContainer.show()
      @addSubView @embedContainer
      @show()

    # embedly uses the https://developers.google.com/safe-browsing/ API
    # to stop phishing/malware sites from being embedded
    if data.safe? and (data.safe is yes or data.safe is 'true')

      # types should be covered, but if the embed call fails partly, default to link
      type = data.object?.type or 'link'

      populateData =
        link_embed   : data
        link_url     : data.url
        link_options : _.extend {}, options, @options

      switch type
        when 'audio', 'xml', 'json', 'ppt', 'rss', 'atom'
          displayEmbedType 'object', populateData

        # this is usually just a single image
        when 'photo','image'
          displayEmbedType 'image', populateData

        # rich is a html object for things like twitter posts
        # link is fallback for things that may or may not have any kind of preview
        # or are links explicitly
        # also captures 'rich content' and makes regular links from that data
        when 'link', 'rich', 'html', 'text', 'video'

          # Unless the provider is whitelisted by us, we will not allow the custom HTML
          # that embedly provides to be displayed, rather use our own small box
          # that shows a  thumbnail, some info about the author and a desc.
          if data.provider_name in @getRichEmbedWhitelist()
            displayEmbedType 'object', populateData

          # the original type needs to be HTML, else it would be a link to a specific
          # file on the web. they can always link to it, it just will not be embedded
          else if data.type in ['html', 'xml', 'text', 'video']
            unless @options.forceType? and options.forceType?
              displayEmbedType 'link', populateData
            else
              displayEmbedType options.forceType or @options.forceType, populateData

          # this can be audio or video files
          else
            html = "Embedding #{data.type or 'unknown'} content like this is not supported."

        # embedly supports many error types. we could display those to the user
        when 'error'
          log 'Embedding error ', data.error_type, data?.error_message
          return 'There was an error'
        else
          log "EmbedBox encountered an unhandled content type '#{type}' - please implement a population method."

      @$('div.embed').addClass 'custom-'+type

    # In the case of unsafe data (most likely phishing), this should be used
    # to log the user, the url and other data to our admins.
    else if data.safe is no
      log 'There was unsafe content.', data, data?.safe_type, data?.safe_message
      @hide()
    else
      log 'EmbedBox encountered an error!', data?.error_type, data?.error_message
      @hide()

  setActiveLink:(url)->
    for item,i in @cache
      for link,j in @embedLinks.linkList.items
        if link.getData().url is url
          link.makeActive()

  embedExistingData:(data={}, options={}, callback=noop)->
    unless data.type is 'error'
      @populateEmbed data, options
      @show()
      callback data
    else
      @hide()  unless @options.hasConfig
      callback no

  fetchEmbed:(url='#', options={}, callback=noop)->

    # if there is no protocol, supply one! embedly doesn't support //
    unless /^(ht|f)tp(s?)\:\/\//.test url then url = 'http://'+url

    # prepare embed.ly options
    embedlyOptions = $.extend {}, {
      endpoint  : 'preview'
      maxWidth  : 530
      maxHeight : 200
      wmode     : 'transparent'
      error     : (node, dict)=> callback? dict
    }, options

    # fetch embed.ly data from the server api
    KD.remote.api.JStatusUpdate.fetchDataFromEmbedly url, embedlyOptions, (oembed)=>
      oembed = JSON.parse Encoder.htmlDecode oembed
      callback oembed[0], embedlyOptions

  embedUrl:(url,options={},callback=noop)->
    # Checking if we have the URL in cached data before requesting it from embedly
    # user URL should be checked for domain, since embedly returns
    # urls without www. even if they are requested with www.
    url_ = url.replace /www\./, ""

    for embed,i in @cache when embed.url?
      # remove trailing slash
      embedUrl = embed.url.replace /\/$/, ""
      if embed.url is url or embedUrl.indexOf(url_,embedUrl.length-url_.length) >= 0
        return @embedExistingData @cache[i], options, callback

    @embedContainer.destroy()  if @embedContainer
    @embedLoader.show()
    @$('div.link-embed').addClass 'loading'
    @fetchEmbed url, options, (data, embedlyOptions)=>
      unless data.type is 'error'
        @resetEmbed()
        @addToCache data
        @populateEmbed data, embedlyOptions
        @show()
        callback data
      else
        @hide() unless @options.hasConfig
        callback no
      @embedLoader.hide()
      @$('div.link-embed').removeClass 'loading'

  pistachio:->
    """
      {{> @embedLoader}}
      {{> @settingsButton}}
      {{> @embedLinks}}
    """
