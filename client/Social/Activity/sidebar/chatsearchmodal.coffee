class ChatSearchModal extends SidebarSearchModal

  constructor: (options = {}, data) ->

    options.cssClass      = KD.utils.curry 'chat-search sidebar-white-modal', options.cssClass
    options.title       or= 'Other Messages:'
    options.placeholder or= 'Search'
    options.noItemText  or= 'You don\'t have any other chats.'
    options.itemClass   or= SidebarMessageItem
    options.endpoints    ?=
      fetch               : KD.singletons.socialapi.message.fetchPrivateMessages
      search              : KD.singletons.socialapi.message.search

    super options, data


  populate: (items) ->

    nonCollaborativeItems = items
      .filter (channel) -> not KD.utils.isChannelCollaborative channel

    super nonCollaborativeItems

