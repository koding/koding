kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView
KDListViewController = kd.ListViewController
KDView = kd.View
SidebarTopicItem = require 'app/activity/sidebar/sidebartopicitem'


module.exports = class ActivityTopicsWidget extends KDCustomHTMLView
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
      noItemFoundWidget   : new KDView
        cssClass          : "no-item-found"
        partial           : "<cite>There are no topics.</cite>"

    @addSubView @listController.getView()

    kd.singletons.socialapi.channel.fetchPopularTopics
      limit: 5
    , @bound 'createTopicsList'

  createTopicsList : (err, data) ->
    @listController.instantiateListItems data
    @listController.hideLazyLoader()



