class AllTopicsModal extends KDModalView

  constructor: (options = {}, data) ->

    options.title    or= 'Browse All Topics'
    options.cssClass or= 'topics all activity-modal'
    options.content  or= ''
    options.overlay   ?= yes
    options.width     ?= 330
    options.height   or= 'auto'

    super options, data


  viewAppended: ->

    @addSubView new KDInputView
      placeholder : 'Search topics...'

    @addSubView new ActivitySideView
      title      : ''
      itemClass  : SidebarTopicItem
      dataPath   : 'popularTopics'
      delegate   : this
      headerLink : new KDCustomHTMLView
      noItemText : 'There are no topics yet, you can create one by having a #hashtag in a post.'
      dataSource : (callback) ->
        KD.singletons.socialapi.channel.fetchPopularTopics
          limit  : 25
        , callback
