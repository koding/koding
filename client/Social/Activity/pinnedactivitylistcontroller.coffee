class PinnedActivityListController extends ActivityListController
  constructor: (options = {}, data) ->
    viewOptions          = options.viewOptions or {}
    viewOptions.cssClass = KD.utils.curry "pinned-activity-list", viewOptions.cssClass

    options.viewOptions         = viewOptions
    options.startWithLazyLoader = no
    options.showHeader          = no
    options.noItemFoundWidget   = no

    super options, data

    @getView().once "viewAppended", =>
      {prefetchedFeeds} = KD
      @instantiateListItems KD.remote.revive prefetchedFeeds["activity.main"].slice 0, 2
