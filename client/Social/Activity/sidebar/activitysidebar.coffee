class ActivitySidebar extends KDCustomScrollView

  skip = 0

  viewAppended:->

    super

    @addHotTopicsAside()
    skip += 3
    @addFollowedTopicsAside()
    skip = 0
    @addThreadsAside()
    skip += 3
    @addMessagesAside()
    skip += 3
    @addChatAside()

    {activityController} = KD.singletons
    activityController.on 'SidebarItemClicked', @bound 'itemClicked'


  itemClicked: (item) ->

    log item


  addHotTopicsAside: ->

    @wrapper.addSubView @hotTopics = new ActivitySideView
      title      : 'HOT'
      cssClass   : 'hot topics'
      itemClass  : SidebarTopicItem
      dataSource : (callback)->
        KD.remote.api.JTag.some {group : 'koding'},
          limit  : 3
          skip   : skip
          sort   : "counts.followers" : -1
        , callback


  addFollowedTopicsAside: ->

    @wrapper.addSubView @followedTopics = new ActivitySideView
      title    : 'Followed Topics'
      cssClass : 'followed topics'
      itemClass : SidebarTopicItem
      dataSource : (callback)->
        KD.remote.api.JTag.some {group : 'koding'},
          limit  : 3
          skip   : skip
          sort   : "counts.followers" : -1
        , callback


  addThreadsAside: ->

    @wrapper.addSubView @threads = new ActivitySideView
      title    : 'Threads'
      cssClass : 'threads users'
      itemClass : SidebarMemberItem
      dataSource : (callback)->
        KD.getGroup().fetchNewestMembers {}, {limit : 3, skip}, callback


  addMessagesAside: ->

    @wrapper.addSubView @messages = new ActivitySideView
      title    : 'Messages'
      cssClass : 'inbox users'
      itemClass : SidebarMemberItem
      dataSource : (callback)->
        KD.getGroup().fetchNewestMembers {}, {limit : 3, skip}, callback


  addChatAside: ->

    @wrapper.addSubView @chat = new ActivitySideView
      title    : 'Chat'
      cssClass : 'chat users'
      itemClass : SidebarMemberItem
      dataSource : (callback)->
        KD.getGroup().fetchNewestMembers {}, {limit : 10, skip : 0}, callback
