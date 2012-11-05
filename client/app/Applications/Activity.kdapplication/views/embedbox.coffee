###

  Expected data structure:

    link :
      link_url                : String
      link_embed              : Object (oembed structure)
      link_embed_hidden_items : Array  (of Strings)
      link_embed_image_index  : Number

###


class EmbedBox extends KDView
  constructor:(options={}, data={})->

    account = KD.whoami()

    @options = options

    @setEmbedCache data.link_cache or data.link?.link_cache or []
    @setEmbedData data.link_embed or data.link?.link_embed or {}
    @setEmbedURL data.link_url or data.link?.link_url or ''
    @setEmbedImageIndex data.link_embed_image_index or data.link?.link_embed_image_index or 0
    @setEmbedHiddenItems data.link_embed_hidden_items or data.link?.link_embed_hidden_items or []


    super options,data


    # top right corner either has the remove-embed button
    # or the report-button (to report malicious content)
    if @options.hasConfig
      @settingsButton = new KDButtonView
        cssClass    : "hide-embed"
        icon        : yes
        iconOnly    : yes
        iconClass   : "hide"
        title       : "hide"
        callback    :=>
          @addEmbedHiddenItem "embed"
          @refreshEmbed()

    else
      @settingsButton = new KDView
      # @settingsButton = new KDButtonView
      #   cssClass    : "report-embed"
      #   icon        : yes
      #   iconOnly    : yes
      #   iconClass   : "report"
      #   title       : "report"
      #   callback    :=>
      #     modal = new KDModalView
      #       title          : "Report inappropriate content"
      #       content        : "<div class='modalformline'>Are you sure you want to report this content?</div>"
      #       height         : "auto"
      #       overlay        : yes
      #       buttons        :
      #         Report       :
      #           style      : "modal-clean-red"
      #           loader     :
      #             color    : "#ffffff"
      #             diameter : 16
      #           callback   : =>
      #             log "Your report should have been sent now."
      #             modal.destroy()


    @setClass "link-embed-box"

    @embedLoader = new KDLoaderView
      cssClass      : "embed-loader hidden"
      size          :
        width       : 30
      loaderOptions :
        color       : "#5f5f5f"
        shape       : "spiral"
        diameter    : 30
        density     : 30
        range       : 0.4
        speed       : 1
        FPS         : 24

    @embedType = data.link_embed?.object?.type or data.link_embed?.type or "link"
    # log "Initital type is ",@embedType

    @embedLinks = new EmbedBoxLinksView
      cssClass : "embed-links-container"
      delegate : @

    @embedLinks.hide()

    @embedContainer = new KDView options, data

    unless data is {} then @hide()

  viewAppended:->
    super()
    @setTemplate @pistachio()
    @template.update()

  loadImages:->
    do =>
      @utils.wait =>
        @$("img").each (i,element)->
          if $(element).attr "data-src"
            $(element).attr "src" : $(element).attr("data-src")
            $(element).removeAttr "data-src"
          element

  refreshEmbed:=>
    @populateEmbed @getEmbedData(), @embedURL, {}, @getEmbedCache()

  resetEmbedAndHide:=>
    @resetEmbed()

    # these resets concern the whole box, not just the embed currently
    # displayed
    @embedLinks.clearLinks()
    @setEmbedCache []

    @hide()

  resetEmbed:=>
    @clearEmbed()

    # these resets only concern the currently displayed embed
    @setEmbedData {}
    @setEmbedURL ''
    @setEmbedHiddenItems []
    @setEmbedImageIndex 0

  clearEmbed:=>
    # here them embed can be prepared for population
    # @$("div.embed").html ""

  clearEmbedAndHide:=>
    @clearEmbed()
    @hide()

  getEmbedDataForSubmit:->
    data              = @getEmbedData()
    unless data.original_title?
      data.original_title = @embedContainer.embedText?.embedTitle?.getOriginalValue() or ""
    data.title        = @embedContainer.embedText?.embedTitle?.titleInput?.getValue() or ""
    unless data.original_description?
      data.original_description = @embedContainer.embedText?.embedDescription?.getOriginalValue() or ""
    data.description  = @embedContainer.embedText?.embedDescription?.descriptionInput?.getValue() or ""

    unless @embedContainer.embedText?.embedTitle?.titleInput?.getValue() is \
           @embedContainer.embedText?.embedTitle?.getOriginalValue()
      data.titleEdited = yes

    unless @embedContainer.embedText?.embedDescription?.descriptionInput?.getValue() is \
           @embedContainer.embedText?.embedDescription?.getOriginalValue()
      data.descriptionEdited = yes
    data

  getEmbedData:->
    isCached = no
    for embed,i in @embedCache
      if embed.url is @getEmbedURL
        isCached = yes
        isChachedIndex = i

    if isCached
      @embedCache[i]
    else
      @embedData

  getEmbedURL:=>
    @embedURL

  getEmbedCache:=>
    @embedCache

  getEmbedImageIndex:=>
    @embedImageIndex

  getEmbedHiddenItems:=>
    @embedHiddenItems

  setEmbedCache:(cache)=>
    unless @embedCache? then @embedCache = []
    for item in cache
      unless item in @embedCache
        if item.url?
          @embedCache.push item
    @embedCache = _.uniq @embedCache

  setEmbedData:(data)=>
    isChached = no
    for embed in @embedCache
      if data.url is embed.url then isCached = yes
    unless isCached
      @embedCache.push data
    @embedData = data

  setEmbedURL:(url)=>
    @embedURL = url

  setEmbedHiddenItems:(ehi)=>
    @embedHiddenItems = ehi

  setEmbedImageIndex:(i)=>
    @embedImageIndex = i

  addEmbedHiddenItem:(item)=>
    if not (item in @embedHiddenItems) then @embedHiddenItems.push item

  removeEmbedHiddenItem:(item)=>
    if (item in @getEmbedHiddenItems()) then delete @embedHiddenItems[@embedHiddenItems.indexOf item]

  getRichEmbedWhitelist:=>
    [
      "SoundCloud"
    ]

  fetchEmbed:(url="#",options={},callback=noop)=>

    # if there is no protocol, supply one! embedly doesn't support //
    unless /^(ht|f)tp(s?)\:\/\//.test url then url = "http://"+url

    # prepare embed.ly options
    embedlyOptions = $.extend {}, {
      # key      : "e8d8b766e2864a129f9e53460d520115"
      endpoint : "preview"
      maxWidth : 530
      maxHeight: 200
      wmode    : "transparent"
      error    : (node, dict)=>
        callback? dict
    }, options

    # fetch embed.ly data from the server api
    KD.remote.api.JStatusUpdate.fetchDataFromEmbedly url, embedlyOptions, (embedData)=>
      oembed = JSON.parse Encoder.htmlDecode embedData

      # embed.ly returns an array with x objects for x urls requested
      @setEmbedData oembed[0]
      @setEmbedURL url
      callback oembed[0],embedlyOptions

    # embed.ly provides this jQuery plugin for client-side embeds

    # requirejs ["http://scripts.embed.ly/jquery.embedly.min.js"], (embedly)=>
    #   $.embedly url, embedlyOptions, (oembed, dict)=>
    #     @setEmbedData oembed
    #     @setEmbedURL url
    #     callback oembed,embedlyOptions

  populateEmbed:(data={},url="#",options={},cache=[])=>
    @setEmbedData data
    @setEmbedURL url
    @setEmbedCache cache unless cache is []

    displayEmbedType=(embedType)=>
      # log "setting up", embedType, @getEmbedData()

      embedOptions = _.extend {}, @options, {
        cssClass : "link-embed clearfix"
        delegate : @
      }

      @embedContainer.destroy()

      switch embedType
        when "link"
          @embedContainer = new EmbedBoxLinkView embedOptions, @getData()
        when "image"
          @embedContainer = new EmbedBoxImageView embedOptions, @getData()
        when "object"
          @embedContainer = new EmbedBoxObjectView embedOptions, @getData()

      @embedContainer.show()

      @addSubView @embedContainer


    # if the whole embed should be hidden, no content needs to be prepared
    if ("embed" in @getEmbedHiddenItems())
      unless (options.forceShow is yes)
        @hide()
        return no
    else
      @show()

    # when the editview calls this, the user can re-disable the embed.
    # if this is not removed from the data, he will not be able to switch
    # on embedding again

    if options.forceShow
      @removeEmbedHiddenItem "embed"

    # embedly uses the https://developers.google.com/safe-browsing/ API
    # to stop phishing/malware sites from being embedded
    if data?.safe? and data?.safe is yes

      # types should be covered, but if the embed call fails partly, default to link
      type = data.object?.type or "link"

      # log "Embedding object type",type, " with data type",data.type

      switch type

        when "audio", "xml", "json", "ppt", "rss", "atom"
          displayEmbedType "object"

          @embedContainer.populate
            link_cache : @getEmbedCache()
            link_embed : data
            link_url : url
            link_options : options
            link_embed_image_index : @getEmbedImageIndex()
            link_embed_hidden_items : @getEmbedHiddenItems()

        # this is usually just a single image
        when "photo","image"
          displayEmbedType "image"

          @embedContainer.populate
            link_embed : data
            link_url : url
            link_options : options
            link_cache : @getEmbedCache()
            link_embed_image_index : @getEmbedImageIndex()
            link_embed_hidden_items : @getEmbedHiddenItems()

          if ("image" in @getEmbedHiddenItems())
            @hide()

        # rich is a html object for things like twitter posts

        # link is fallback for things that may or may not have any kind of preview
        # or are links explicitly
        # also captures "rich content" and makes regular links from that data
        when "link", "rich", "html", "text", "video"

          # Unless the provider is whitelisted by us, we will not allow the custom HTML
          # that embedly provides to be displayed, rather use our own small box
          # that shows a  thumbnail, some info about the author and a desc.

          if (data?.provider_name in @getRichEmbedWhitelist())
            displayEmbedType "object"

            @embedContainer.populate
              link_embed : data
              link_url : url
              link_cache : @getEmbedCache()
              link_options : _.extend {}, options, @options
              link_embed_image_index : @getEmbedImageIndex()
              link_embed_hidden_items : @getEmbedHiddenItems()

          # the original type needs to be HTML, else it would be a link to a specific
          # file on the web. they can always link to it, it just will not be embedded
          else if data?.type in ["html", "xml", "text", "video"]

            displayEmbedType "link"

            @embedContainer.populate
              link_embed : data
              link_cache : @getEmbedCache()
              link_url : url
              link_options : _.extend {}, options, @options
              link_embed_image_index : @getEmbedImageIndex()
              link_embed_hidden_items : @getEmbedHiddenItems()

          # this can be audio or video files
          else
            html = "Embedding #{data.type or "unknown"} content like this is not supported."

          @setLinkFavicon url

        # embedly supports many error types. we could display those to the user
        when "error"
          log "Embedding error ",data?.error_type,data?.error_message
          return "There was an error"
        else
          log "EmbedBox encountered an unhandled content type '#{type}' - please implement a population method."

      @$("div.embed").addClass "custom-"+type

    # In the case of unsafe data (most likely phishing), this should be used
    # to log the user, the url and other data to our admins.
    else if data?.safe is no
      log "There was unsafe content.",data,data?.safe_type,data?.safe_message
      @hide()
    else
      log "EmbedBox encountered an Error!",data?.error_type,data?.error_message
      @hide()

  setLinkFavicon:(url)->
    for item,i in @getEmbedCache()
      for link,j in @embedLinks.linkList.items
        if link.getData().url is url
          link.makeActive()
        if item.url is link.getData().url
          link.setFavicon item.favicon_url
            # unless link.favicon is item.favicon_url


  embedExistingData:(data={},options={},callback=noop,cache=[])=>
    unless data.type is "error"

      @clearEmbed()
      @populateEmbed data, data.url, options, cache

      # althou the hide/show should be handled from outside the embed,
      # this is a fallback

      unless "embed" in @getEmbedHiddenItems then @show() else @hide()

      callback data
    else
      @hide()
      callback no

  embedUrl:(url,options={},callback=noop)=>

    # Checking if we have the URL in cached data before requesting it from embedly

    for embed,i in @embedCache
      # for comparison reasons, both urls have to be sanitized a bit. this could
      # use some more complexity (NEEDS TESTING FOR EDGE CASES)

      # user URL should be checked for domain, since embedly returns
      # urls without www. even if they are requested with www.
      url_ = url.replace /www\./, ""

      # remove trailing slash
      if embed.url? then embedUrl = embed.url.replace /\/$/, ""

      # log embed.url, embedUrl, url, url_, embed.url?.indexOf(url,embed.url?.length-url.length)
      if embed.url? and (embed.url is url or not (embedUrl.indexOf(url_,embedUrl.length-url_.length) is -1))
        @setEmbedData @embedCache[i]
        @setEmbedURL url
        @embedExistingData @embedCache[i], options, callback, @getEmbedCache()
        return no

    # else we just request the embed

    @embedLoader.show()
    @$("div.link-embed").addClass "loading"
    @fetchEmbed url, options, (data,embedlyOptions)=>
      unless data.type is "error"
        @resetEmbed()
        @populateEmbed data, url, embedlyOptions

        # we can expect the embedUrl call not to happen on a hidden embed
        @show()

        callback data
      else
        @hide()
        callback no
      @embedLoader.hide()
      @$("div.link-embed").removeClass "loading"


  pistachio:->
    """
      {{> @embedLoader}}
      {{> @settingsButton}}
      {{> @embedLinks}}
    """