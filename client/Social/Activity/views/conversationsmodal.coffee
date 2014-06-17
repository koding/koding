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
      itemClass  : SidebarTopicItem
      dataPath   : 'followedChannels'
      delegate   : this
      headerLink : new KDCustomHTMLView
      noItemText : "You don't follow anything yet."
      dataSource : (callback) ->
        KD.singletons.socialapi.channel.fetchPinnedMessages
          limit : 10
        , callback
