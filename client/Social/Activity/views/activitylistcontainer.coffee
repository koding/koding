class ActivityListContainer extends JView

  constructor:(options = {}, data)->
    options.cssClass = "activity-content feeder-tabs"

    super options, data

    @pinnedListController = new PinnedActivityListController
      delegate    : this
      itemClass   : ActivityListItemView
      viewOptions :
        cssClass  : "hidden"

    @pinnedListWrapper = @pinnedListController.getView()

    @pinnedListController.on "Loaded", =>
      @togglePinnedList.show()
      @pinnedListController.getListView().show()

    @togglePinnedList = new KDCustomHTMLView
      cssClass   : "toggle-pinned-list hidden"
      # click      : KDView::toggleClass.bind @pinnedListWrapper, "hidden"

    @togglePinnedList.addSubView new KDCustomHTMLView
      tagName    : "span"
      cssClass   : "title"
      partial    : "Most Liked"

    @controller = new ActivityListController
      delegate          : @
      itemClass         : ActivityListItemView
      showHeader        : yes
      # wrapper           : no
      # scrollView        : no

    @listWrapper = @controller.getView()
    @filterWarning = new FilterWarning

    @controller.ready => @emit "ready"

  setSize:(newHeight)->
    # @controller.scrollView.setHeight newHeight - 28 # HEIGHT OF THE LIST HEADER

  viewAppended: ->
    super
    @togglePinnedList.show()  if @pinnedListController.getItemCount()

  pistachio:->
    """
      {{> @filterWarning}}
      {{> @togglePinnedList}}
      {{> @pinnedListWrapper}}
      {{> @listWrapper}}
    """
