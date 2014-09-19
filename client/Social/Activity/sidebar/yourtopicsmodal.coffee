class YourTopicsModal extends SidebarSearchModal

  constructor: (options = {}, data) ->

    options.title       or= 'Browse Your Topics'
    options.placeholder or= 'Search all topics...'
    options.noItemFound or= 'You don\'t follow any topics yet. You can search for some topics above e.g HTML, CSS, golang.'
    options.endpoints ?=
      fetch            : KD.singletons.socialapi.channel.fetchFollowedChannels
      search           : KD.singletons.socialapi.channel.searchTopics

    super options, data