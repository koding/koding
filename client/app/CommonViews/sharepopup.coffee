class SharePopup extends JView

  constructor: (options={}, data)->

    options.cssClass          ?= "share-popup"
    options.shortenURL        ?= true
    options.url               ?= ""

    options.twitter         ?= {}
    options.twitter.enabled ?= true
    options.twitter.text    ?= ""

    options.facebook         ?= {}
    options.facebook.enabled ?= true

    options.linkedin         ?= {}
    options.linkedin.enabled ?= true

    options.newTab          ?= {}
    options.newTab.enabled  ?= true
    options.newTab.url      ?= options.url

    super options, data

    @urlInput = new KDInputView
      cssClass    : "share-input"
      type        : "text"
      placeholder : "building url..."
      attributes  :
        readonly  : yes
      width       : 50

      if options.shortenURL
        KD.utils.shortenUrl options.url, (shorten)=>
          @urlInput.setValue shorten
          @urlInput.$().select()
      else
        @urlInput.setValue options.url
        @urlInput.$().select()

    @once "viewAppended", =>
      @urlInput.$().select()


    @twitterShareLink  = @buildTwitterShareLink()
    @facebookShareLink = @buildFacebookShareLink()
    @linkedInShareLink = @buildLinkedInShareLink()

    @openNewTabButton = @buildNewTabLink()

  buildURLInput:()->
    @urlInput = new KDInputView
      cssClass    : "share-input"
      type        : "text"
      placeholder : "building url..."
      attributes  :
        readonly  : yes
      width       : 50

    options = @getOptions()
    if options.shortenURL
      KD.utils.shortenUrl options.url, (shorten)=>
        @urlInput.setValue shorten
        @urlInput.$().select()
        return @urlInput
    else
      @urlInput.setValue options.url
      @urlInput.$().select()
      return @urlInput


  buildTwitterShareLink:()->
    if @getOptions().twitter.enabled
      return new KDCustomHTMLView
        tagName   : 'a'
        cssClass  : "share-twitter icon-link"
        partial   : "<span class='icon tw'></span>"
        click     : (event)=>
          KD.utils.stopDOMEvent event
          shareText = @getOptions().twitter.text or @getOptions().text
          window.open(
            "https://twitter.com/intent/tweet?text=#{encodeURIComponent shareText}&via=koding&source=koding",
            "twitter-share-dialog",
            "width=500,height=350,left=#{Math.floor (screen.width/2) - (500/2)},top=#{Math.floor (screen.height/2) - (350/2)}"
          )

    # if twitter is not provided, do not show
    return new KDView

  buildFacebookShareLink:()->
    if @getOptions().facebook.enabled
      return new KDCustomHTMLView
        tagName   : 'a'
        cssClass  : "share-twitter icon-link"
        partial   : "<span class='icon tw'></span>"
        click     : (event)=>
          KD.utils.stopDOMEvent event
          window.open(
            "https://www.facebook.com/sharer/sharer.php?u=#{encodeURIComponent(@getOptions().url)}",
            "facebook-share-dialog",
            "width=626,height=436,left=#{Math.floor (screen.width/2) - (500/2)},top=#{Math.floor (screen.height/2) - (350/2)}"
          )

  buildLinkedInShareLink:()->
    if @getOptions().linkedin.enabled
      return new KDCustomHTMLView
        tagName   : 'a'
        cssClass  : "share-twitter icon-link"
        partial   : "<span class='icon tw'></span>"
        click     : (event)=>
          KD.utils.stopDOMEvent event
          link = "http://www.linkedin.com/shareArticle?mini=true&url=#{encodeURIComponent(@getOptions().url)}&title=#{encodeURIComponent("Join Koding.com")}&summary=#{encodeURIComponent("The next generation development environment")}&source=koding.com"
          console.log "link"
          console.log link
          window.open(
            link,
            "linkedin-share-dialog",
            "width=626,height=436,left=#{Math.floor (screen.width/2) - (500/2)},top=#{Math.floor (screen.height/2) - (350/2)}"
          )

    # if twitter is not provided, do not show
    return new KDView

  buildNewTabLink:()->
    if @getOptions().newTab.enabled
      return new CustomLinkView
        cssClass    : "icon-link"
        title       : ""
        href        :  @getOptions().newTab.url
        target      :  @getOptions().newTab.url
        icon        :
          cssClass  : 'new-page'
          placement : 'right'

    # if  is not provided, do not show
    return new KDView

  pistachio: ->
    """
    {{> @urlInput}}
    {{> @openNewTabButton}}
    {{> @twitterShareLink}}
    {{> @facebookShareLink}}
    {{> @linkedInShareLink}}
    """

