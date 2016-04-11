kd = require 'kd'

ActivityAutoCompleteUserItemView         = require 'activity/views/activityautocompleteuseritemview'
ChatHead                                 = require 'activity/views/chathead'
FetchingActivityAutoCompleteUserItemView = require 'activity/views/fetchingactivityautocompleteuseritemview'

module.exports = class ResourceSearchAccountsView extends kd.View

  ENTER = 13

  constructor: (options = {}, data) ->

    super options, data

    accountHeads = new kd.View { cssClass : 'account-heads' }
    @controller  = new kd.AutoCompleteController
      name                : 'account'
      placeholder         : 'Type a username...'
      itemClass           : ActivityAutoCompleteUserItemView
      fetchingItemClass   : FetchingActivityAutoCompleteUserItemView
      outputWrapper       : accountHeads
      listWrapperCssClass : 'resource-management-search'
      outputWrapper       : accountHeads
      selectedItemClass   : ChatHead
      itemDataPath        : '_id'
      dataSource          : @bound 'fetchAccounts'

    autoCompleteView = @controller.getView()
    autoCompleteView.on 'keydown', (event) ->
      return event.preventDefault()  if event.which is ENTER

    @addSubView autoCompleteView
    @addSubView accountHeads


  setForm: (form) -> @controller.setOption 'form', form


  reset: -> @controller.reset()


  fetchAccounts: ({ inputValue }, callback) ->

    { search } = kd.singletons
    search.searchAccounts inputValue, { showCurrentUser: yes }
      .then callback
      .catch (err) ->
        console.warn 'Error while autoComplete: ', err
        callback []
