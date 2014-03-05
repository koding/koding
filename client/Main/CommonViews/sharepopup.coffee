class SharePopup extends JView

  constructor: (options={}, data)->

    options.cssClass          ?= "share-popup"
    options.shortenURL        ?= true
    options.url               ?= ""

    options.gplus            ?= {}
    options.gplus.enabled    ?= true

    options.twitter         ?= {}
    options.twitter.enabled ?= true
    options.twitter.text    ?= ""

    options.facebook         ?= {}
    options.facebook.enabled ?= true

    options.linkedin         ?= {}
    options.linkedin.enabled ?= true
    options.linkedin.title   ?= "Koding.com"
    options.linkedin.text    ?= options.url or "The next generation development environment"

    options.newTab          ?= {}
    options.newTab.enabled  ?= true
    options.newTab.url      ?= options.url

    super options, data

    @urlInput = urlInput = new KDInputView
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
      urlInput.setValue options.url
      urlInput.$().select()

    @once "viewAppended", =>
      @urlInput.$().select()


    @gPlusShareLink    = @buildGPlusShareLink()
    @twitterShareLink  = @buildTwitterShareLink()
    @facebookShareLink = @buildFacebookShareLink()
    @linkedInShareLink = @buildLinkedInShareLink()

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

  buildGPlusShareLink:()->
    if @getOptions().gplus.enabled
      link = "https://plus.google.com/share?url=#{encodeURIComponent(@getOptions().url)}"
      return @generateView(link, "gplus")
    return new KDView

  buildTwitterShareLink:()->
    if @getOptions().twitter.enabled
      shareText = @getOptions().twitter.text or @getOptions().text
      link = "https://twitter.com/intent/tweet?text=#{encodeURIComponent shareText}&via=koding&source=koding"
      return @generateView link, "twitter"

    # if twitter is not provided, do not show
    return new KDView

  buildFacebookShareLink:()->
    if @getOptions().facebook.enabled
      link = "https://www.facebook.com/sharer/sharer.php?u=#{encodeURIComponent(@getOptions().url)}"
      return @generateView link, "facebook"
    return new KDView

  buildLinkedInShareLink:()->
    if @getOptions().linkedin.enabled
      link = "http://www.linkedin.com/shareArticle?mini=true&url=#{encodeURIComponent(@getOptions().url)}&title=#{encodeURIComponent(@getOptions().linkedin.title)}&summary=#{encodeURIComponent(@getOptions().linkedin.text)}&source=#{location.origin}"
      return @generateView(link, "linkedin")
    return new KDView

  generateView:(link, provider)->
    return new KDCustomHTMLView
      tagName   : 'a'
      # todo when adding new icons, replace those two lines
      cssClass  : "share-#{provider} icon-link"
      # cssClass  : "share-twitter icon-link"
      partial   : "<span class='icon'></span>"
      click     : (event)=>
        KD.utils.stopDOMEvent event
        window.open(
          link,
          "#{provider}-share-dialog",
          "width=626,height=436,left=#{Math.floor (screen.width/2) - (500/2)},top=#{Math.floor (screen.height/2) - (350/2)}"
        )

  pistachio: ->
    """
    {{> @urlInput}}
    {{> @gPlusShareLink}}
    {{> @linkedInShareLink}}
    {{> @facebookShareLink}}
    {{> @twitterShareLink}}
    """

