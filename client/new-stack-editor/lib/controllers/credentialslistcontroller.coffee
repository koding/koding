kd = require 'kd'
JView = require 'app/jview'
Events = require '../events'

CredentialListItem              = require '../views/credentiallistitem'
AccountCredentialList           = require 'app/views/credentiallist/accountcredentiallist'
AccountCredentialListController = require 'app/views/credentiallist/accountcredentiallistcontroller'


module.exports = class StackCredentialListController extends AccountCredentialListController

  constructor: (options = {}, data) ->

    options      =
      limit      : 15
      viewClass  : AccountCredentialList
      itemClass  : CredentialListItem
      baseQuery  :
        provider : { $ne: 'custom' }

    super options, data

    list = @getListView()
    listView = @getView()

    statusView = list.addSubView new kd.CustomHTMLView
      cssClass : 'status-view'

    statusView.addSubView new kd.ButtonView
      cssClass : 'kdbutton action-button solid green compact save-button'
      callback : => @emit Events.CredentialChangesSaveRequested
      title    : 'Save Changes'

    statusView.addSubView new kd.ButtonView
      cssClass : 'kdbutton action-button solid gray compact revert-button'
      callback : => @emit Events.CredentialChangesRevertRequested
      title    : 'Revert Changes'

    @filterView  = listView.addSubView new JView
      cssClass   : 'filter-view hidden'
      pistachio  : '
        Currently selected provider: <b>{{#(provider)}}</b> <cite />
      '
      click      : (event) ->
        list.emit Events.CredentialFilterChanged
        kd.utils.stopDOMEvent event
    , { provider : '' }

    list.on Events.CredentialFilterChanged, (provider) =>

      return  if provider and not @filterView.hasClass 'hidden'

      filter = null
      filter = { provider }  if provider

      @filterView.setData filter

      if filter
      then @filterView.show()
      else @filterView.hide()

      @filterByProvider filter



  showLazyLoader: ->

    super

    @getView().emit Events.LazyLoadStarted


  hideLazyLoader: ->

    super

    @getView().emit Events.LazyLoadFinished


  addListItems: (items) ->

    super items

    @emit Events.CredentialListUpdated
