class ActivityTopicsWidget extends KDCustomHTMLView
  constructor: (options = {}) ->
    options.cssClass    = 'popular-topics-widget activity-widget'
    super options

    @addSubView new KDCustomHTMLView
      tagName             : 'h3'
      partial             : 'Most active Channels'

    @listController = new KDListViewController
      itemClass           : SidebarTopicItem
      startWithLazyLoader : yes
      lazyLoaderOptions   :
        spinnerOptions    :
          loaderOptions   :
            shape         : 'spiral'
            color         : '#a4a4a4'
          size            :
            width         : 40
            height        : 40

    @addSubView @listController.getView()

    KD.singletons.socialapi.channel.fetchPopularTopics
      limit  : 3
    , @bound 'createTopicsList'

  createTopicsList : (err, data) ->
    @listController.instantiateListItems data
    @listController.hideLazyLoader()

