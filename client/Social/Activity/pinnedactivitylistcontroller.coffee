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
      feeds = KD.prefetchedFeeds["activity.main"] or []
      return  unless feeds.length
      @instantiateListItems KD.remote.revive feeds.slice 0, 2

  postIsCreated: ->
