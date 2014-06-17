class YourTopicsModal extends KDModalView

  constructor: (options = {}, data) ->

    options.title    or= 'Browse All Your Topics'
    options.cssClass or= 'topics your activity-modal'
    options.content  or= ''
    options.overlay   ?= yes
    options.width     ?= 330
    options.height   or= 'auto'

    super options, data

    {appManager, router} = KD.singletons
    appManager.tell 'Activity', 'bindModalDestroy', this, router.visitedRoutes.last


  viewAppended: ->

    @addSubView new KDInputView
      placeholder : 'Search topics...'

    @addSubView new ActivitySideView
      title      : 'My Feeds'
      itemClass  : SidebarTopicItem
      dataPath   : 'followedChannels'
      delegate   : this
      headerLink : new KDCustomHTMLView
      noItemText : "You don't follow anything yet."
      dataSource : (callback) ->
        KD.singletons.socialapi.channel.fetchFollowedChannels
          limit : 25
        , callback

