class ShareLink extends KDButtonView
  constructor: (options = {}, data) ->
    options.cssClass      = KD.utils.curry "share-icon #{options.provider}", options.cssClass
    options.partial       = """<span class="icon"></span>"""
    options.iconOnly     ?= yes
    options.trackingName ?= ""
    super options, data

  click: (event) ->
    KD.utils.stopDOMEvent event

    {provider, trackingName} = @getOptions()

    window.open(
      @getUrl(),
      "#{provider}-share-dialog",
      "width=626,height=436,left=#{Math.floor (screen.width/2) - (500/2)},top=#{Math.floor (screen.height/2) - (350/2)}"
    )

    KD.mixpanel "#{provider} share link, click in #{trackingName}", user: KD.nick()

class TwitterShareLink extends ShareLink
  constructor: (options = {}, data) ->
    options.provider = "twitter"
    super options, data

  getUrl: () ->
    {url} = @getOptions()
    text  = "Koding is giving away 100TB this week - my link gets you a 5GB VM! #{url} @koding is AWESOME! #Crazy100TBWeek"
    return "https://twitter.com/intent/tweet?text=#{encodeURIComponent text}&source=koding"

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
    text  = "Koding is giving away 100TB this week - my link gets you a 5GB VM! #{url} @koding is AWESOME! #Crazy100TBWeek"
    return "http://www.linkedin.com/shareArticle?mini=true&url=#{encodeURIComponent url}&title=#{encodeURIComponent @title}&summary=#{encodeURIComponent text}&source=#{location.origin}"

  title: "Join me @koding!"
