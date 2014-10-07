class MoreChannelsModal extends SidebarSearchModal

  constructor: (options = {}, data) ->

    options.cssClass      = KD.utils.curry 'more-channels sidebar-white-modal', options.cssClass
    options.title       or= 'Other Channels you are following:'
    options.placeholder or= 'Search'
    options.endpoints    ?=
      fetch               : KD.singletons.socialapi.channel.fetchFollowedChannels
      search              : KD.singletons.socialapi.channel.searchTopics

    super options, data

    @setSkipCount()


  viewAppended: ->

    super

    @listController.getListView().on 'ItemShouldBeSelected', (item, event) =>

      KD.utils.stopDOMEvent event

      KD.singletons.router.handleRoute item.getOption 'route'
      @destroy()


  setSkipCount: ->

    {mainView: {activitySidebar}} = KD.singletons
    {sections: {channels}}        = activitySidebar
    {listController}              = channels

    @skipCount = listController.getItemCount() - 2 or 0


  fetch: (options = {}, callback = noop) ->

    options.skip ?= @skipCount

    super options, callback


  getLazyLoadOptions: ->

    skip  = @listController.getItemCount()
    skip += @skipCount  unless @searchActive

    return {skip}
