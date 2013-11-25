class ActivityTicker extends JView
  constructor:(options={}, data)->
    options.cssClass      = "activity-right-block"

    super options, data

    @listController = new KDListViewController
      startWithLazyLoader : yes
      viewOptions :
        type      : "activities"
        cssClass  : "activities"
        itemClass : ActivityTickerItem

    @listView = @listController.getView()

    KD.remote.api.ActivityTicker.fetch null, (err, items = []) =>
      @listController.hideLazyLoader()
      @listController.addItem item for item in items  unless err

  pistachio:
    """
    <div class="activity-ticker">
      <h3>Activity Feed <i class="cog-icon"></i></h3>
      {{> @listView}}
    </div>
    """
