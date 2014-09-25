class ChatSearchModal extends SidebarSearchModal

  constructor: (options = {}, data) ->

    options.title       or= 'Browse Your Chats'
    options.placeholder or= 'Search all chats...'
    options.noItemText  or= 'You don\'t have any started chats yet.'
    options.itemClass   or= SidebarMessageItem
    options.endpoints    ?=
      fetch            : KD.singletons.socialapi.message.fetchPrivateMessages
      search           : KD.singletons.socialapi.message.search

    super options, data
