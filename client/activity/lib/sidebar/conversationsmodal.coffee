kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView
KDInputView = kd.InputView
KDListViewController = kd.ListViewController
SidebarSearchModal = require 'app/activity/sidebar/sidebarsearchmodal'
SidebarPinnedItem = require 'app/activity/sidebar/sidebarpinneditem'


module.exports = class ConversationsModal extends SidebarSearchModal

  constructor: (options = {}, data) ->

    options.cssClass    or= 'conversations activity-modal'
    options.width        ?= 330
    options.height      or= 'auto'
    options.overlay      ?= yes
    options.endpoints     =
      fetch               : kd.singletons.socialapi.channel.fetchPinnedMessages
      search              : kd.singletons.socialapi.channel.byName

    options.title       or= 'Conversations you follow'
    options.placeholder or= 'Search'
    options.noItemFound or= 'You don\'t follow any conversations yet.'
    options.content     or= ''

    super options, data

    {appManager, router} = kd.singletons
    appManager.tell 'Activity', 'bindModalDestroy', this, router.visitedRoutes.last


  viewAppended: ->

    @addSubView new KDInputView
      cssClass    : 'hidden'
      placeholder : 'Search conversations...'
      keyup       : kd.utils.debounce 300, @bound 'search'

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


