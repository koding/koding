class ConversationsModal extends YourTopicsModal

  constructor: (options = {}, data) ->

    options.title    or= 'Conversations you follow'
    options.cssClass or= 'conversations activity-modal'
    options.content  or= ''
    options.overlay   ?= yes
    options.width     ?= 330
    options.height   or= 'auto'
    options.endpoints  =
      fetch            : KD.singletons.socialapi.channel.fetchPinnedMessages
      search           : KD.singletons.socialapi.channel.byName

    super options, data

    {appManager, router} = KD.singletons
    appManager.tell 'Activity', 'bindModalDestroy', this, router.visitedRoutes.last


  viewAppended: ->

    @addSubView new KDInputView
      cssClass    : 'hidden'
      placeholder : 'Search conversations...'
      keyup       : KD.utils.debounce 300, @bound 'search'

    @listController = new KDListViewController
      startWithLazyLoader : yes
      noItemFoundWidget   : new KDCustomHTMLView
        cssClass          : 'nothing hidden'
        partial           : 'You didn\'t participate in any conversations yet.'
      lazyLoadThreshold   : 100
      lazyLoaderOptions   :
        spinnerOptions    :
          size            :
            width         : 16
            height        : 16
        partial           : ''
      useCustomScrollView : yes
      viewOptions         :
        type              : 'activities'
        itemClass         : SidebarPinnedItem
        cssClass          : 'activities'

    @addSubView @listController.getView()

    @listController.customScrollView.wrapper.on 'LazyLoadThresholdReached', @bound 'handleLazyLoad'

    @fetch {}, @bound 'populate'