class EmbedBox extends KDView
  constructor:(options={}, data={})->

    account = KD.whoami()

    @options = options

    @embedData = {}
    @embedURL = ''

    @embedImageIndex = data.link_image_index or 0
    @embedHiddenItems = data.link_embed_hidden_items or []


    super options,data

    if @options.hasDropdown or KD.checkFlag 'super-admin'
      @settingsButton = new KDButtonViewWithMenu
        cssClass    : 'transparent activity-settings-context activity-settings-menu embed-box-settings'
        title       : ''
        icon        : yes
        delegate    : @
        iconClass   : "arrow"
        menu        : @settingsMenu data
        callback    : (event)=>
          event.preventDefault()
          @settingsButton.contextMenu event
    else
      @settingsButton = new KDCustomHTMLView tagName : 'span', cssClass : 'hidden'


    @setClass "link-embed-box"

    @embedLoader = new KDLoaderView
      cssClass      : "hidden"
      size          :
        width       : 30
      loaderOptions :
        color       : "#444"
        shape       : "spiral"
        diameter    : 30
        density     : 30
        range       : 0.4
        speed       : 1
        FPS         : 24

    unless data is {} then @hide()

  settingsMenu:(data)=>

    account        = KD.whoami()
    mainController = @getSingleton('mainController')

    # only during creation of when the user is the link owner should
    # this menu exist

    if @options.hasDropdown
      menu =
        'Remove Image from Preview' :
          callback : =>
            @addEmbedHiddenItem "image"
            @refreshEmbed()
            @getDelegate()?.emit "embedHideItem", @embedHiddenItems
            no
        'Remove Preview'   :
          callback : =>
            @embedHiddenItems.push "embed"
            @refreshEmbed()
            @getDelegate()?.emit "embedHideItem", @embedHiddenItems
            no

      return menu

  viewAppended:->
    super()
    @setTemplate @pistachio()
    @template.update()

  refreshEmbed:=>
    @populateEmbed @getEmbedData(), @embedURL

  resetEmbedAndHide:=>
    @resetEmbed()
    @hide()

  resetEmbed:=>
    @clearEmbed()
    @setEmbedData {}
    @setEmbedURL ''
    @setEmbedHiddenItems []
    @setEmbedImageIndex 0

  clearEmbed:=>
    @$("div.embed").html ""

  clearEmbedAndHide:=>
    @clearEmbed()
    @hide()

  getEmbedData:=>
    @embedData

  getEmbedURL:=>
    @embedURL

  getEmbedImageIndex:=>
    @embedImageIndex

  getEmbedHiddenItems:=>
    @embedHiddenItems

  setEmbedData:(data)=>
    @embedData = data

  setEmbedURL:(url)=>
    @embedURL = url

  setEmbedHiddenItems:(ehi)=>
    @embedHiddenItems = ehi

  setEmbedImageIndex:(i)=>
    @embedImageIndex = i

  addEmbedHiddenItem:(item)=>
    if not (item in @embedHiddenItems) then @embedHiddenItems.push item

  fetchEmbed:(url="#",options={},callback=noop)=>

    requirejs ["http://scripts.embed.ly/jquery.embedly.min.js"], (embedly)=>
      embedlyOptions = $.extend {}, {
        key      : "e8d8b766e2864a129f9e53460d520115"
        endpoint : "preview"
        maxWidth : 560
        maxHeight: 300
        wmode    : "transparent"
        error    : (node, dict)=>
          callback? dict
      }, options

      # if there is no protocol, supply one! embedly doesn't support //
      unless /^(ht|f)tp(s?)\:\/\//.test url then url = "http://"+url

      $.embedly url, embedlyOptions, (oembed, dict)=>
        @setEmbedData oembed
        @setEmbedURL url
        callback oembed,embedlyOptions

  populateEmbed:(data={},url="#",options={})=>

    # if the whole embed should be hidden, no content needs to be prepared
    if "embed" in @getEmbedHiddenItems()
      @hide()
      return no

    # embedly uses the https://developers.google.com/safe-browsing/ API
    # to stop phishing/malware sites from being embedded
    if data?.safe? and data?.safe is yes

      # types should be covered, but if the embed call fails partly, default to link
      type = data?.object?.type or "link"

      switch type
        when "html" then html = data?.object?.html or "This link has no Preview available. Oops."
        when "audio" then html = data?.object?.html or "This link has no Preview available. Oops."
        when "video" then html = data?.object?.html or "This link has no Preview available. Oops."
        when "text" then html = data?.object?.html or "This link has no Preview available. Oops."
        when "xml" then html = data?.object?.html or "This link has no Preview available. Oops."
        when "json" then html = data?.object?.html or "This link has no Preview available. Oops."
        when "ppt" then html = data?.object?.html or "This link has no Preview available. Oops."
        when "rss","atom" then html = data?.object?.html or "This link has no Preview available. Oops."

        # this is usually just a single image
        when "photo","image"
          html = """<a href="#{data?.url or "#"}" target="_blank"><img src="#{data?.images?[0]?.url}" style="max-width:#{options.maxWidth+"px" or "560px"};max-height:#{options.maxHeight+"px" or "300px"}" title="#{data?.title or ""}" /></a>"""
          if ("image" in @getEmbedHiddenItems())
            @hide()

        # rich is a html object for things like twitter posts
        # when "rich"
        #   html = data?.object?.html
        #   html = $(html).addClass "custom-twitter"

        # fallback for things that may or may not have any kind of preview
        # or are links explicitly
        # also captures "rich content" and makes regular links from that data
        when "link","rich"
          html = """
              <div class="preview_image #{if ("image" in @getEmbedHiddenItems()) or not data?.images?[0]? then "hidden" else ""}">
                <a class="preview_link" target="_blank" href="#{data.url or url}"><img class="thumb" src="#{data?.images?[0]?.url or "this needs a default url"}" title="#{(data.title + (if data.author_name then " by "+data.author_name else "")) or "untitled"}"/></a>
              </div>
              <div class="preview_text">
               <a class="preview_text_link" target="_blank" href="#{data.url or url}">
                <div class="preview_title">#{data.title or data.url}</div>
               </a>
                <div class="author_info #{if data.author_name then "" else "hidden"}">written by <a href="#{data.author_url or "#"}" target="_blank">#{data.author_name}</a></div>
                <div class="provider_info">for <strong>#{data.provider_name or "the internet"}</strong>#{if data.provider_url then " at <a href=\"" +data.provider_url+"\" target=\"_blank\">"+data.provider_display+"</a>" else ""}</div>
               <a class="preview_text_link" target="_blank" href="#{data.url or url}">
                <div class="description">#{data.description or ""}</div>
               </a>
              </div>
              <div class="preview_link_pager #{unless (@options.hasDropdown) and not("image" in @getEmbedHiddenItems()) and data?.images? and (data?.images?.length > 1) then "hidden" else ""}">
                <a class="preview_link_switch previous #{if @getEmbedImageIndex() is 0 then "disabled" else ""}">&lt;</a><a class="preview_link_switch next #{if @getEmbedImageIndex() is @getEmbedData()?.images?.length then "disabled" else ""}">&gt;</a>
                <div class="thumb_count"><span class="thumb_nr">#{@getEmbedImageIndex()+1 or "1"}</span>/<span class="thumb_all">#{data?.images?.length}</span> <span class="thumb_text">Thumbs</span></div>
              </div>
          """

        # embedly supports many error types. we could display those to the user
        when "error"
          log "Embedding error ",data?.error_type,data?.error_message
          return "There was an error"
        else
          log "EmbedBox encountered an unhandled content type '#{type}' - please implement a population method."

      @$("div.embed").html html
      @$("div.embed").addClass "custom-"+type

    # In the case of unsafe data (most likely phishing), this should be used
    # to log the user, the url and other data to our admins.
    else if data?.safe is no
      log "There was unsafe content.",data,data?.safe_type,data?.safe_message
      @hide()
    else
      log "EmbedBox encountered an Error!",data?.error_type,data?.error_message

  embedExistingData:(data={},options={},callback=noop)=>
    unless data.type is "error"
      @clearEmbed()
      @populateEmbed data, data.url, options
      @show()
      callback data
    else
      callback no

  embedUrl:(url,options={},callback=noop)=>
    @embedLoader.show()
    @fetchEmbed url, options, (data,embedlyOptions)=>
      unless data.type is "error"
        @clearEmbed()
        @populateEmbed data, url, embedlyOptions
        @show()
        @embedLoader.hide()
        callback data
      else
        callback no

  click:(event)=>
    if  $(event.target).hasClass "preview_link_switch"

      if ($(event.target).hasClass "next") and (@getEmbedData().images?.length-1 > @getEmbedImageIndex() )
        @setEmbedImageIndex @getEmbedImageIndex() + 1
        @$("a.preview_link_switch.previous").removeClass "disabled"

      if ($(event.target).hasClass "previous") and (@getEmbedImageIndex() > 0)
        @setEmbedImageIndex @getEmbedImageIndex() - 1
        @$("a.preview_link_switch.next").removeClass "disabled"

      @$("div.preview_image img.thumb").attr src : @getEmbedData()?.images?[@getEmbedImageIndex()]?.url
      @$("span.thumb_nr").html @getEmbedImageIndex()+1

      if @getEmbedImageIndex() is 0
        @$("a.preview_link_switch.previous").addClass "disabled"

      else if @getEmbedImageIndex() is (@getEmbedData().images?.length-1)
        @$("a.preview_link_switch.next").addClass "disabled"



  pistachio:->
    """
      {{> @settingsButton}}
      {{> @embedLoader}}
      <div class="link-embed clearfix">
        <div class="embed"></div>
      </div>
    """