class ShareLink extends KDButtonView
  constructor: (options = {}, data) ->
    options.cssClass   = KD.utils.curry "share-icon #{options.provider}", options.cssClass
    options.partial    = """<span class="icon"></span>"""
    options.iconOnly  ?= yes
    super options, data

  click: (event) ->
    KD.utils.stopDOMEvent event

    {provider, url} = @getOptions()

    window.open(
      url,
      "#{provider}-share-dialog",
      "width=626,height=436,left=#{Math.floor (screen.width/2) - (500/2)},top=#{Math.floor (screen.height/2) - (350/2)}"
    )

class TwitterShareLink extends ShareLink
  constructor: (options = {}, data) ->
    options.provider = "twitter"
    options.url      = @getURL options.url
    super options, data

  getURL: (shareLink) ->
    text = "Learn, code and deploy together to powerful VMs - @koding, the dev environment from the future! #{shareLink}"
    return "https://twitter.com/intent/tweet?text=#{encodeURIComponent text}&via=koding&source=koding"

class FacebookShareLink extends ShareLink
  constructor: (options = {}, data) ->
    options.provider = "facebook"
    options.url      = "https://www.facebook.com/sharer/sharer.php?u=#{encodeURIComponent options.url}"
    super options, data

class LinkedInShareLink extends ShareLink
  constructor: (options = {}, data) ->
    options.provider = "linkedin"
    options.url      = @getURL options.url
    super options, data

  getURL: (shareLink) ->
    text = "Learn, code and deploy together to powerful VMs - @koding, the dev environment from the future! #{shareLink}"
    return "http://www.linkedin.com/shareArticle?mini=true&url=#{encodeURIComponent shareLink}&title=#{encodeURIComponent @title}&summary=#{encodeURIComponent text}&source=#{location.origin}"

  title: "Join me @koding!"
