class MoreChannelsModal extends SidebarSearchModal

  constructor: (options = {}, data) ->

    options.cssClass      = KD.utils.curry 'more-channels sidebar-dark-modal', options.cssClass
    options.title       or= 'Other Channels you are following:'
    options.placeholder or= 'Search'
    options.endpoints    ?=
      fetch               : KD.singletons.socialapi.channel.fetchFollowedChannels
      search              : KD.singletons.socialapi.channel.searchTopics

    super options, data


  fetch: (options = {}, callback = noop) ->

    options.skip ?= 9

    super options, callback
