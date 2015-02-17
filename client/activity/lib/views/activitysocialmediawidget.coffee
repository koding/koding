kd = require 'kd'
ActivityBaseWidget = require './activitybasewidget'

module.exports = class ActivitySocialMediaWidget extends ActivityBaseWidget

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'socialmedia-widget', options.cssClass

    super options, data


  pistachio: ->
    twitter_link  = "https://twitter.com/intent/follow?user_id=42704386"
    facebook_link = "https://facebook.com/koding"
    """
      <a href="#{twitter_link}" target="_blank" class="kdbutton solid no-text-transform light-gray medium tw"><span class="button-title">Koding on Twitter</span></a>
      <a href="#{facebook_link}" target="_blank" class="kdbutton solid no-text-transform light-gray medium fb"><span class="button-title">Koding on Facebook</span></a>
    """
