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

class OnlineUsers extends ActivityRightBase
  constructor:(options={}, data)->
    @itemClass = ActiveUserItemView

    super options, data

    KD.whoami().fetchMyOnlineFollowingsFromGraph {}, @renderItems.bind this

  pistachio:
    """
    <div class="activity-ticker">
      <h3>Online Users</h3>
      {{> @tickerListView}}
    </div>
    """

class ActiveUsers extends ActivityRightBase
  constructor:(options={}, data)->
    @itemClass = ActiveUserItemView

    super options, data

    KD.remote.api.ActiveItems.fetchUsers {}, @renderItems.bind this

  pistachio:
    """
    <div class="activity-ticker">
      <h3>Members</h3>
      {{> @tickerListView}}
    </div>
    """

class ActiveTopics extends ActivityRightBase
  constructor:(options={}, data)->
    @itemClass = ActiveTopicItemView

    super options, data

    KD.remote.api.ActiveItems.fetchTopics {}, @renderItems.bind this

  pistachio:
    """
    <div class="activity-ticker">
      <h3>Topics</h3>
      {{> @tickerListView}}
    </div>
    """
