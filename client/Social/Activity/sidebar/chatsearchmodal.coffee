class ChatSearchModal extends SidebarSearchModal

  constructor: (options = {}, data) ->

    options.cssClass      = KD.utils.curry 'chat-search sidebar-dark-modal', options.cssClass
    options.title       or= 'Other Messages:'
    options.placeholder or= 'Search'
    options.noItemText  or= 'You don\'t have any other chats.'
    options.itemClass   or= SidebarMessageItem
    options.endpoints    ?=
      fetch               : KD.singletons.socialapi.message.fetchPrivateMessages
      search              : KD.singletons.socialapi.message.search

    super options, data

    @setSkipCount()


  setSkipCount: ->

    {mainView: {activitySidebar}} = KD.singletons
    {sections: {messages}}        = activitySidebar
    {listController}              = messages

    @skipCount = listController.getItemCount() or 0


  fetch: (options = {}, callback = noop) ->

    options.skip ?= @skipCount

    super options, callback


  getLazyLoadOptions: ->

    skip  = @listController.getItemCount()
    skip += @skipCount  unless @searchActive

    return {skip}
