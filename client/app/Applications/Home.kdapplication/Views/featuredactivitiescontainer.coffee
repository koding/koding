class FeaturedActivitiesContainer extends JView

  constructor:(options = {}, data)->

    options.domId    = "featured-activities-container"
    options.cssClass = "activity-content feeder-tabs"

    super options, data
    @updatePartial ''

    @controller = new HomeActivityListController
      delegate          : this
      itemClass         : ActivityListItemView
      showHeader        : yes

    @listWrapper = @controller.getView()
    @listWrapper.setPartial '<div class="kdview feeder-header clearfix"><span>Featured Activity</span></div>'

  viewAppended:->
    super
    @emit 'ready'

  pistachio:->

    """
    {{> @listWrapper}}
    """


class HomeActivityListController extends ActivityListController

  loadView : KDListViewController::loadView
