kd             = require 'kd'
nick           = require 'app/util/nick'
getReferralUrl = require 'app/util/getReferralUrl'
CustomViews    = require './customviews'
getSocialLinks = require './getSocialLinks'


module.exports = class ReferralCustomViews extends CustomViews

  createListController = (itemClass) ->
    new kd.ListViewController
      itemClass           : itemClass ? require './accountreferralsystemlistitem'
      useCustomScrollView : yes
      lazyLoadThreshold   : 10
      lazyLoaderOptions   :
        spinnerOptions    :
          loaderOptions   : shape: 'spiral', color: '#a4a4a4'
          size            : width: 20, height: 20
        partial           : ''

  followLazyLoad = (controller, fetcher, limit) ->

    skip = 0
    busy = no

    controller.on 'LazyLoadThresholdReached', kd.utils.debounce 300, ->

      return  controller.hideLazyLoader()  if busy
      busy  = yes
      skip += limit

      fetcher { limit, skip }, (err, data)->
        controller.hideLazyLoader()
        return  if err or data?.rewards?.length is 0
        controller.instantiateListItems data.rewards
        busy = no


  @views extends

    totalSpace: (total) =>

      container = @views.container 'total-space'

      @addTo container,
        view       :
          partial  : "#{total}GB"
          cssClass : 'total'
        text       : 'Earned Free Space'

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
        text_invite   : 'Your personal invite link:'
        link          :
          href        : getReferralUrl nick()
          target      : '_blank'

      return container

    loader: (cssClass)->
      new kd.LoaderView {
        cssClass, showLoader: yes,
        size: width: 40, height: 40
      }

    list: ({data, itemClass, fetcher, limit}) ->

      controller = createListController itemClass
      list       = controller.getListView()

      controller.replaceAllItems data

      if data?.length > 0

        header = new kd.ListItemView {cssClass: 'referral-item header'}, {}
        header.partial = -> "
          <div>Friend</div>
          <div>Status</div>
          <div>Last Activity</div>
          <div>Space Earned</div>
        "
        list.addItemView header, 0
        followLazyLoad controller, fetcher, limit

      else

        list.addSubView new kd.View
          cssClass : 'no-referral'
          partial  : "You don't have any referrals yet."

      __view = controller.getView()
      return { __view, controller }

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
      # since the implementation of kd.ProgressBarView creates that
      # element in the ::viewAppended step ~ GG
      kd.utils.defer ->
        progressBar.bar.setCss 'background', color

      return container
