kd             = require 'kd'
nick           = require 'app/util/nick'
getReferralUrl = require 'app/util/getReferralUrl'

shareLinks =
  twitter  : (url)->
    url = "Register to Koding with my link to get 500MB of extra free space! #{url}"
    return "https://twitter.com/intent/tweet?text=#{url}&via=koding&source=koding"

  google   : (url)->
    return "https://plus.google.com/share?url=#{url}"

  facebook : (url)->
    return "https://www.facebook.com/sharer/sharer.php?u=#{url}"

  linkedin : (url)->
    text   = "Register to Koding with my link to get 500MB of extra free space!"
    title  = "Join me @koding!"
    return "http://www.linkedin.com/shareArticle?mini=true&url=#{url}&title=#{title}&summary=#{text}&source=#{location.origin}"

  mail     : (url)->
    title  = "Sign up for Koding, get 500MB more"
    text   = "#{nick()} has invited you to Koding. As a special offer, if you
              sign up to Koding today, we'll give you an additional 500MB of
              cloud storage. Use this (#{url}) link to register and claim
              your reward."

    return "mailto:?subject=#{title}&body=#{text}"

module.exports = getSocialLinks = (provider)->

  link = shareLinks[provider] encodeURIComponent getReferralUrl nick()

  callback = (event)->
    kd.utils.stopDOMEvent event
    global.open(
      link, "#{provider}-share-dialog",
      "width=626,height=436,left=#{Math.floor (global.screen.width/2) - (500/2)},top=#{Math.floor (global.screen.height/2) - (350/2)}"
    )

  return {callback, link}
