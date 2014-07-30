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
      return console.error "unimplemented feature"

      return  unless KD.prefetchedFeeds
      feeds = KD.prefetchedFeeds["mostlikedactivity.main"] or []
      return @instantiateListItems KD.remote.revive feeds  if feeds.length

      options =
        sort  : "meta.likes": -1
        limit : 5
        from  : Date.now() - (24 * 60 * 60 * 1000)

      KD.remote.api.JNewStatusUpdate.fetchGroupActivity options, (err, items) =>
        return log "fetching pinned activity list failed", err  if err
        @instantiateListItems items
        @emit "Loaded"

  postIsCreated: ->
