kd                = require 'kd'
KDProgressBarView = kd.ProgressBarView

CustomViews       = require './customviews'
getSocialLinks    = require './getSocialLinks'


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

    progressBar: (options) ->
      new kd.ProgressBarView options

    progress: (options) =>

      {current, max, title, color} = options

      initial   = Math.round (current / max) * 100
      container = @views.container 'progress'
      color     = {green: '#409531', yellow: '#F7B91A'}[color] or color

      {progressBar} = @addTo container,
        text_label  : title
        progressBar : {initial}
        text_value  : "#{current}GB"

      # We are defering here because we don't have ::bar element yet
      # since the implementation of KDProgressBarView creates that
      # element in the ::viewAppended step which is wrong. ~ GG
      kd.utils.defer ->
        progressBar.bar.setCss "background", color

      return container
