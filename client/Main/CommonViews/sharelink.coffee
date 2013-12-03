class ShareLink extends KDButtonView
  constructor: (options = {}, data) ->
    options.cssClass   = KD.utils.curry "share-icon #{options.provider}", options.cssClass
    options.partial    = """<span class="icon"></span>"""
    options.iconOnly  ?= yes
    super options, data

  click: (event) ->
    KD.utils.stopDOMEvent event

    {provider} = @getOptions()

    window.open(
      @getUrl(),
      "#{provider}-share-dialog",
      "width=626,height=436,left=#{Math.floor (screen.width/2) - (500/2)},top=#{Math.floor (screen.height/2) - (350/2)}"
    )

    KD.kdMixpanel.track "#{provider} Share Link Clicked", $user: KD.nick()

class TwitterShareLink extends ShareLink
  constructor: (options = {}, data) ->
    options.provider = "twitter"
    super options, data

  getUrl: () ->
    {url} = @getOptions()
    text  = "Learn, code and deploy together to powerful VMs - @koding, the dev environment from the future! #{url}"
    return "https://twitter.com/intent/tweet?text=#{encodeURIComponent text}&via=koding&source=koding"

class FacebookShareLink extends ShareLink
  constructor: (options = {}, data) ->
    options.provider = "facebook"
    super options, data

  getUrl: ->
    "https://www.facebook.com/sharer/sharer.php?u=#{encodeURIComponent @getOptions().url}"

class LinkedInShareLink extends ShareLink
  constructor: (options = {}, data) ->
    options.provider = "linkedin"
    super options, data

  getUrl: () ->
    {url} = @getOptions()
    text  = "Learn, code and deploy together to powerful VMs - @koding, the dev environment from the future! #{url}"
    return "http://www.linkedin.com/shareArticle?mini=true&url=#{encodeURIComponent url}&title=#{encodeURIComponent @title}&summary=#{encodeURIComponent text}&source=#{location.origin}"

  title: "Join me @koding!"
