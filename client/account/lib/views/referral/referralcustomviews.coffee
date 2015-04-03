CustomViews = require './customviews'
getSocialLinks = require './getSocialLinks'

module.exports = class ReferralCustomViews extends CustomViews

  @views extends

    totalSpace: (total) =>

      container = @views.container 'total-space'

      @addTo container,
        view       :
          partial  : "#{total}GB"
          cssClass : 'total'
        text       : "Earned Free Space"

      return container

    socialIcons: ({providers}) =>

      container = @views.container 'social'

      providers.forEach (provider)=>

        {callback, link} = getSocialLinks provider
        options   =
          link    :
            title : ''
            icon  : cssClass: provider

        if provider is 'mail'
        then options.link.href  = link
        else options.link.click = callback

        @addTo container, options

      return container

    shareBox: ({title, subtitle}) =>

      container = @views.container 'share-box'

      @addTo container,
        text_title    : title
        text_subtitle : subtitle
        socialIcons   :
          providers   : ['facebook', 'linkedin', 'twitter', 'google', 'mail']
        text_invite   : "Personal invite link"
        link          :
          href        : "https://koding.com/R/gokmen"

      return container
