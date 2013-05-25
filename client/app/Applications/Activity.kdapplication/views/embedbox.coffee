###
  Expected data structure:
    
    link :
      link_url                : String
      link_embed              : Object (oembed structure)
###

class EmbedBox extends KDView

  constructor:(options={}, data={})->

    @embeddedData    = data.link_embed or data.link?.link_embed or {}
    @embeddedUrl     = data.link_url or data.link?.link_url or ''
    @embeddedCache   = []
    @hasValidContent = no

    super options,data

    # top right corner either has the remove-embed button
    # or the report-button (to report malicious content)
    if @options.hasConfig
      @settingsButton = new KDButtonView
        cssClass    : 'hide-embed'
        icon        : yes
        iconOnly    : yes
        iconClass   : 'hide'
        title       : 'hide'
        callback    :=>
          @addEmbedHiddenItem 'embed'
          @refreshEmbed()
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
      delegate : @
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

  refreshEmbed:->
    @populateEmbed @embeddedData, @embeddedUrl, {}

  resetEmbedAndHide:->
    @resetEmbed()
    @embedLinks.clearLinks()
    @hasValidContent = no
    @hide()

  # these resets only concern the currently displayed embed
  resetEmbed:->
    @embeddedData = {}
    @embeddedUrl  = ''

  addToCache:(item)->
    @embeddedCache.push item  if item.url? and item not in @embeddedCache

  getembeddedDataForSubmit:->
    data             = @embeddedData
    embedText        = @embedContainer.embedText
    data.title       = embedText?.embedTitle?.titleInput?.getValue() or ''
    data.description = embedText?.embedDescription?.descriptionInput?.getValue() or ''

    unless data.original_title?
      data.original_title = embedText?.embedTitle?.getOriginalValue() or ''

    unless data.original_description?
      data.original_description = embedText?.embedDescription?.getOriginalValue() or ''

    data

  getRichEmbedWhitelist:-> [] # add provider name here if we dont want to embed

  fetchEmbed:(url='#',options={},callback=noop)->

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
    KD.remote.api.JStatusUpdate.fetchDataFromEmbedly url, embedlyOptions, (embeddedData)=>
      oembed = JSON.parse Encoder.htmlDecode embeddedData

      # embed.ly returns an array with x objects for x urls requested
      @embeddedData    = oembed[0]
      @embeddedUrl     = url
      @hasValidContent = yes

      @addToCache oembed[0]

      callback oembed[0], embedlyOptions

  populateEmbed:(data={},url='#',options={},cache=[])->
    @embeddedData = data
    @embeddedUrl  = url

    displayEmbedType=(embedType)=>
      @hasValidContent = yes

      embedOptions = _.extend {}, @options, {
        cssClass : 'link-embed clearfix'
        delegate : @
      }

      @embedContainer.destroy()

      switch embedType
        when 'link'
          @embedContainer = new EmbedBoxLinkView embedOptions, @getData()
        when 'image'
          @embedContainer = new EmbedBoxImageView embedOptions, @getData()
        when 'object'
          @embedContainer = new EmbedBoxObjectView embedOptions, @getData()
        else
          @embedContainer = new EmbedBoxLinkView embedOptions, @getData()

      @embedContainer?.show()
      @addSubView @embedContainer
      @show()

    # embedly uses the https://developers.google.com/safe-browsing/ API
    # to stop phishing/malware sites from being embedded
    if data?.safe? and data?.safe is yes

      # types should be covered, but if the embed call fails partly, default to link
      type = data.object?.type or 'link'

      populateData =
        link_embed   : data
        link_url     : url
        link_options : _.extend {}, options, @options
        link_cached  : @embeddedCache

      switch type
        when 'audio', 'xml', 'json', 'ppt', 'rss', 'atom'
          displayEmbedType 'object'
          @embedContainer.populate populateData

        # this is usually just a single image
        when 'photo','image'
          displayEmbedType 'image'
          @embedContainer.populate populateData

        # rich is a html object for things like twitter posts
        # link is fallback for things that may or may not have any kind of preview
        # or are links explicitly
        # also captures 'rich content' and makes regular links from that data
        when 'link', 'rich', 'html', 'text', 'video'

          # Unless the provider is whitelisted by us, we will not allow the custom HTML
          # that embedly provides to be displayed, rather use our own small box
          # that shows a  thumbnail, some info about the author and a desc.
          if (data?.provider_name in @getRichEmbedWhitelist())
            displayEmbedType 'object'
            @embedContainer.populate populateData

          # the original type needs to be HTML, else it would be a link to a specific
          # file on the web. they can always link to it, it just will not be embedded
          else if data?.type in ['html', 'xml', 'text', 'video']

            if (not @options.forceType? and not options.forceType?)
              displayEmbedType 'link'
            else
              displayEmbedType options.forceType or @options.forceType

            @embedContainer.populate populateData

          # this can be audio or video files
          else
            html = "Embedding #{data.type or 'unknown'} content like this is not supported."

        # embedly supports many error types. we could display those to the user
        when 'error'
          log 'Embedding error ', data?.error_type, data?.error_message
          return 'There was an error'
        else
          log "EmbedBox encountered an unhandled content type '#{type}' - please implement a population method."

      @$('div.embed').addClass 'custom-'+type

    # In the case of unsafe data (most likely phishing), this should be used
    # to log the user, the url and other data to our admins.
    else if data?.safe is no
      log 'There was unsafe content.',data,data?.safe_type,data?.safe_message
      @hide()
    else
      log 'EmbedBox encountered an Error!',data?.error_type,data?.error_message
      @hide()

  embedExistingData:(data={}, options={}, callback=noop, cache=[])->
    unless data.type is 'error'
      @clearEmbed()
      @populateEmbed data, data.url, options, cache
      @show()
      callback data
    else
      @hide()  unless @options.hasConfig
      callback no

  embedUrl:(url,options={},callback=noop)->

    # Checking if we have the URL in cached data before requesting it from embedly
    # user URL should be checked for domain, since embedly returns
    # urls without www. even if they are requested with www.
    url_ = url.replace /www\./, ""

    for embed,i in @embeddedCache when embed.url?
      # remove trailing slash
      embeddedUrl = embed.url.replace /\/$/, ""
      if embed.url is url or embeddedUrl.indexOf(url_,embeddedUrl.length-url_.length) >= 0
        @embeddedData = @embeddedCache[i]
        @embeddedUrl  = url
        @embedExistingData @embeddedCache[i], options, callback, @embeddedCache
        return no

    @embedLoader.show()
    @$('div.link-embed').addClass 'loading'
    @fetchEmbed url, options, (data,embedlyOptions)=>
      unless data.type is 'error'
        @resetEmbed()
        @populateEmbed data, url, embedlyOptions
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
