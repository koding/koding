class ActivityTicker extends JView
  constructor:(options={}, data)->
    options.cssClass      = "activity-right-block"

    super options, data

    @tickerController = new KDListViewController
      startWithLazyLoader : yes
      viewOptions :
        type      : "activities"
        cssClass  : "activities"
        itemClass : ActivityTickerItem

    @tickerListView = @tickerController.getView()

    KD.remote.api.ActivityTicker.fetch null, (err, items = []) =>
      @tickerController.hideLazyLoader()
      @tickerController.addItem item for item in items  unless err

    #### Popular Users

    @activeUsersController = new KDListViewController
      startWithLazyLoader : yes
      viewOptions :
        type      : "activities"
        cssClass  : "activities"
        itemClass : ActiveUserItemView

    @activeUsersListView = @activeUsersController.getView()

    KD.remote.api.ActiveItems.fetchUsers null, (err, items)=>
      @activeUsersController.hideLazyLoader()
      @activeUsersController.addItem item for item in items  unless err

    #### Popular Topics

    @activeTopicsController = new KDListViewController
      startWithLazyLoader : yes
      viewOptions :
        type      : "activities"
        cssClass  : "activities"
        itemClass : ActiveTopicItemView

    @activeTopicsListView = @activeTopicsController.getView()

    KD.remote.api.ActiveItems.fetchTopics null, (err, items)=>
      @activeTopicsController.hideLazyLoader()
      @activeTopicsController.addItem item for item in items  unless err

  pistachio:
    """
    <div class="activity-ticker">
      <h3>Activity Feed <i class="cog-icon"></i></h3>
      {{> @tickerListView}}
    </div>

    <div class="activity-ticker">
      <h3>Members</h3>
      {{> @activeUsersListView}}
    </div>

    <div class="activity-ticker">
      <h3>Topics</h3>
      {{> @activeTopicsListView}}
    </div>
    """
