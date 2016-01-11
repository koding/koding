kd = require 'kd'
SidebarSearchModal = require 'app/activity/sidebar/sidebarsearchmodal'


module.exports = class MoreChannelsModal extends SidebarSearchModal

  constructor: (options = {}, data) ->

    options.cssClass          = kd.utils.curry 'more-channels sidebar-white-modal', options.cssClass
    options.title           or= 'Other Channels you are following:'
    options.placeholder     or= 'Search'
    options.endpoints        ?=
      fetch                   : kd.singletons.socialapi.channel.fetchFollowedChannels
      search                  : kd.singletons.socialapi.channel.searchTopics
    options.emptySearchText or= 'Sorry, your search did not have any results'

    super options, data


  viewAppended: ->

    super

    @listController.getListView().on 'ItemShouldBeSelected', (item, event) =>

      kd.utils.stopDOMEvent event

      kd.singletons.router.handleRoute item.getOption 'route'
      @destroy()
