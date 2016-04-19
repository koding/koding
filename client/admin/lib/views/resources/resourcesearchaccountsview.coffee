kd = require 'kd'

ActivityAutoCompleteUserItemView         = require 'activity/views/activityautocompleteuseritemview'
ChatHead                                 = require 'activity/views/chathead'
FetchingActivityAutoCompleteUserItemView = require 'activity/views/fetchingactivityautocompleteuseritemview'

getFullnameFromAccount = require 'app/util/getFullnameFromAccount'
Encoder                = require 'htmlencode'

module.exports = class ResourceSearchAccountsView extends kd.View

  ENTER     = 13
  BACKSPACE = 8

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
      selectedItemClass   : ChatHead
      itemDataPath        : '_id'
      dataSource          : @bound 'fetchAccounts'

    autoCompleteView = @controller.getView()
    autoCompleteView.on 'keydown', @bound 'handleKeydown'

    @addSubView accountHeads
    @addSubView autoCompleteView


  setForm: (form) -> @controller.setOption 'form', form


  reset: -> @controller.reset()


  handleKeydown: (event) ->

    return event.preventDefault()  if event.which is ENTER
    return  unless lastItemData = @controller.getSelectedItemData().last

    input  = @controller.getView()
    val    = input.getValue()
    [item] = (item for item in @controller.itemWrapper.getSubViews() when item.getData() is lastItemData)

    resetInput = =>
      input.setPlaceholder @controller.getOptions().placeholder
      input.unsetClass 'delete-mode'
      item.unsetClass 'selected'

    if event.which is BACKSPACE and val is ''

      if item.hasClass 'selected'
        @controller.removeFromSubmitQueue item, lastItemData
        resetInput()
      else
        fullname = getFullnameFromAccount lastItemData
        input.setClass 'delete-mode'
        input.setPlaceholder "Hit backspace to remove #{Encoder.htmlDecode fullname}"
        item.setClass 'selected'
    else
      resetInput()


  fetchAccounts: ({ inputValue }, callback) ->

    { search } = kd.singletons
    search.searchAccounts inputValue, { showCurrentUser: yes }
      .then callback
      .catch (err) ->
        console.warn 'Error while autoComplete: ', err
        callback []
