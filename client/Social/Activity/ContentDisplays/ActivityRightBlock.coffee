class ActivityRightBase extends JView
  constructor:(options={}, data)->
    super options, data

    @tickerController = new KDListViewController
      startWithLazyLoader : yes
      viewOptions :
        type      : "activities"
        cssClass  : "activities"
        itemClass : @itemClass

    @tickerListView = @tickerController.getView()

  renderItems: (err, items=[])->
    @tickerController.hideLazyLoader()
    @tickerController.addItem item for item in items  unless err

  pistachio:->
    """
    <div class="activity-ticker">
      <h3>#{@getOption 'title'}</h3>
      {{> @tickerListView}}
    </div>
    """

class OnlineUsers extends ActivityRightBase
  constructor:(options={}, data)->
    @itemClass = ActiveUserItemView

    options.title = "Online Users"
    super options, data

    KD.whoami().fetchMyOnlineFollowingsFromGraph {}, @bound 'renderItems'

class ActiveUsers extends ActivityRightBase
  constructor:(options={}, data)->
    @itemClass = ActiveUserItemView

    options.title = "Active Users"
    super options, data

    KD.remote.api.ActiveItems.fetchUsers {}, @bound 'renderItems'

class ActiveTopics extends ActivityRightBase
  constructor:(options={}, data)->
    @itemClass = ActiveTopicItemView

    options.title = "Active Topics"
    super options, data

    KD.remote.api.ActiveItems.fetchTopics {}, @bound 'renderItems'
