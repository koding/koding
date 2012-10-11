class EmbedBox extends KDView
  constructor:(options={}, data={})->

    account = KD.whoami()

    if data.originId? and (data.originId is KD.whoami().getId()) or KD.checkFlag 'super-admin'
      @settingsButton = new KDButtonViewWithMenu
        cssClass    : 'transparent activity-settings-context activity-settings-menu embed-box-settings'
        title       : ''
        icon        : yes
        delegate    : @
        iconClass   : "arrow"
        menu        : @settingsMenu data
        callback    : (event)=> @settingsButton.contextMenu event
    else
      @settingsButton = new KDCustomHTMLView tagName : 'span', cssClass : 'hidden'

    super options,data

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

    @embedData = {}

    unless data is {} then @hide()

  settingsMenu:(data)->

    account        = KD.whoami()
    mainController = @getSingleton('mainController')

    if data.originId is KD.whoami().getId()
      menu =
        'Remove Image(s) from Preview'     :
          callback : =>
            # mainController.emit 'ActivityItemEditLinkClicked', data
        'Remove Preview'   :
          callback : =>
            # @confirmDeletePost data

      return menu

  viewAppended:->
    super()
    @setTemplate @pistachio()
    @template.update()

  clearEmbed:=>
    @$("div.embed").html ""
    @embedData = {}

  clearEmbedAndHide:=>
    @clearEmbed()
    @hide()

  getEmbedData:=>
    @embedData

  fetchEmbed:(url,options,callback=noop)=>

    requirejs ["http://scripts.embed.ly/jquery.embedly.min.js"], (embedly)=>
      embedlyOptions = $.extend {}, {
        key      : "e8d8b766e2864a129f9e53460d520115"
        maxWidth : 560
        maxHeight: 300
        wmode    : "transparent"
        error    : (node, dict)=>
          callback? dict
      }, options

      $.embedly url, embedlyOptions, (oembed, dict)=>
        @embedData = oembed
        callback oembed

  populateEmbed:(data={},url="#")=>

    # replace this when using preview instead of oembed
    prettyLink = (link)->
      link.replace("http://","").replace("https://","").replace("www.","")

    type = data.type or "link"

    switch type
      when "html" then html = data?.code
      when "audio" then html = data?.code
      when "video" then html = data?.code
      when "text" then html = data?.code
      when "xml" then html = data?.code
      when "json" then html = data?.code
      when "ppt" then html = data?.code
      when "rss","atom" then html = data?.code
      when "photo","image" then html = data?.code
      when "rich" then html = data?.code


      # fallback for things that may or may not have any kind of preview
      when "link"
        # log data
        html = """
          <div class="embed custom-link">
            <div class="preview_image #{unless data.thumbnail_url? then "hidden" else ""}">
              <a class="preview_link" target="_blank" href="#{data.url or url}"><img class="thumb" src="#{data.thumbnail_url or "this needs a default url"}" title="#{data.title or "untitled"}"/></a>
            </div>
            <div class="preview_text">
             <a class="preview_text_link" target="_blank" href="#{data.url or url}">
              <div class="preview_title">#{data.title or "untitled"}</div>
              <div class="provider_info">Provided by <strong>#{data.provider_name or "the internet"}</strong>#{if data.provider_url then " at <strong>"+prettyLink(data.provider_url)+"</strong>" else ""}</div>
              <div class="description">#{data.description or ""}</div>
             </a>
            </div>
          </div>
        """
      when "error" then return "There was an error"
      else
        log "EmbedBox encountered an unhandled content type '#{type}' - please implement a population method."

    # log "EmbedBox used type",type, html

    @$("div.link-embed").html html


  embedUrl:(url,options={},callback=noop)=>
    # @embedLoader.show()
    @fetchEmbed url, options, (data)=>
      unless data.type is "error" then @clearEmbed()
      @populateEmbed data, url
      # @embedLoader.hide()
      @show()
      callback data

  pistachio:->
    """
      {{> @settingsButton}}
      {{> @embedLoader}}
      <div class="link-embed clearfix">
      </div>
    """