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

    @hide()

    @embedData = {}

  settingsMenu:(data)->

    account        = KD.whoami()
    mainController = @getSingleton('mainController')

    if data.originId is KD.whoami().getId()
      menu =
        'Remove Image(s)'     :
          callback : =>
            # mainController.emit 'ActivityItemEditLinkClicked', data
        'Remove Preview'   :
          callback : =>
            # @confirmDeletePost data

      return menu

    if KD.checkFlag 'super-admin'
      menu =
        'MARK USER AS TROLL' :
          callback : =>
            mainController.markUserAsTroll data
        'UNMARK USER AS TROLL' :
          callback : =>
            mainController.unmarkUserAsTroll data
        'Delete Post' :
          callback : =>
            @confirmDeletePost data

      return menu


  viewAppended:->
    super()
    @setTemplate @pistachio()
    @template.update()

  clearEmbed:=>
    @$("div.embed").remove()
    @hide()

  getEmbedData:=>
    @embedData

  fetchEmbed:(url,options,callback=noop)=>

    requirejs ["http://scripts.embed.ly/jquery.embedly.min.js"], (embedly)=>

      embedlyOptions = {
        key      : "e8d8b766e2864a129f9e53460d520115"
        maxWidth : 560
        width    : 560
        wmode    : "transparent"
      }

      $.extend yes, embedlyOptions, options

      $.embedly url, embedlyOptions, (oembed, dict)=>
        @embedData = oembed
        callback oembed

  populateEmbed:(data)=>
    @$("div.link-embed").html data?.code

  embedUrl:(url,options={},callback=noop)=>
    @clearEmbed()
    @fetchEmbed url, options, (data)=>
      @populateEmbed data
      @show()
      callback data

  pistachio:->
    """
      {{> @settingsButton}}
      <div class="link-embed"></div>
    """