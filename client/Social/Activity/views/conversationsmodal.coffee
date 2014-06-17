class ConversationsModal extends KDModalView

  constructor: (options = {}, data) ->

    options.title    or= 'Conversations you follow'
    options.cssClass or= 'conversations activity-modal'
    options.content  or= ''
    options.overlay   ?= yes
    options.width     ?= 330
    options.height   or= 'auto'

    super options, data

    {appManager, router} = KD.singletons
    appManager.tell 'Activity', 'bindModalDestroy', this, router.visitedRoutes.last


  viewAppended: ->

    @addSubView new KDInputView
      placeholder : 'Search conversations...'

    @addSubView new ActivitySideView
      title      : ''
      cssClass   : 'conversations your activity-modal'
      itemClass  : SidebarPinnedItem
      dataPath   : 'pinnedMessages'
      delegate   : this
      noItemText : "You didn't participate in any conversations yet."
      dataSource : (callback) ->
        KD.singletons.socialapi.channel.fetchPinnedMessages
          limit : 10
        , callback
