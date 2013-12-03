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
    <div class="right-block-box">
      <h3>#{@getOption 'title'}</h3>
      {{> @tickerListView}}
    </div>
    """

class OnlineUsers extends ActivityRightBase
  constructor:(options={}, data)->
    @itemClass = ActiveUserItemView

    options.title    = "Online Users"
    options.cssClass = "online-users"
    super options, data

    KD.whoami().fetchMyOnlineFollowingsFromGraph {}, @bound 'renderItems'

class ActiveUsers extends ActivityRightBase
  constructor:(options={}, data)->
    @itemClass = ActiveUserItemView

    options.title    = "Active Users"
    options.cssClass = "active-users"
    super options, data

    KD.remote.api.ActiveItems.fetchUsers {}, @bound 'renderItems'

class ActiveTopics extends ActivityRightBase
  constructor:(options={}, data)->
    @itemClass = ActiveTopicItemView

    options.title    = "Active Topics"
    options.cssClass = "active-topics"
    super options, data

    KD.remote.api.ActiveItems.fetchTopics {}, @bound 'renderItems'
