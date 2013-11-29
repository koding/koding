class ActivityTicker extends JView
  constructor:(options={}, data)->
    options.cssClass      = "activity-right-block"

    super options, data

    @listController = new KDListViewController
      lazyLoadThreshold: .99
      viewOptions :
        type      : "activities"
        cssClass  : "activities"
        itemClass : ActivityTickerItem

    @listView = @listController.getView()

    @listController.on "LazyLoadThresholdReached", @bound "load"

    @load()

  load: ->
    options =
      limit : 20
      skip  : @listController.getItemCount() or 0

    KD.remote.api.ActivityTicker.fetch options, (err, items = []) =>
      @listController.hideLazyLoader()
      unless err
        @listController.addItem item for item in items when item.source? and item.target? and item.as?

  pistachio:
    """
    <div class="activity-ticker right-block-box">
      <h3>Activity Feed <i class="cog-icon"></i></h3>
      {{> @listView}}
    </div>
    """
