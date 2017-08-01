kd = require 'kd'

remote = require 'app/remote'
Events = require '../events'

CredentialListItem              = require '../views/credentiallistitem'
AccountCredentialList           = require 'app/views/credentiallist/accountcredentiallist'
AccountCredentialListController = require 'app/views/credentiallist/accountcredentiallistcontroller'


module.exports = class CredentialsListController extends AccountCredentialListController


  constructor: (options = {}, data) ->

    options         =
      limit         : 15
      viewClass     : AccountCredentialList
      itemClass     : CredentialListItem
      fetcherMethod : remote.api.JCredential.some$
      baseQuery     :
        provider    : { $ne: 'custom' }

    super options, data

    list = @getListView()
    listView = @getView()

    @getOption('noItemFoundWidget').addSubView @_createAddCredentialMenuButton
      title    : 'Create New'

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

    @selectionView = listView.addSubView new kd.View
      cssClass   : 'selection-view hidden'
      pistachio  : '
        Currently selected provider: <b>{{#(provider)}}</b> <cite />
      '
    , { provider : '' }

    @on 'NewItemAdded', (item) =>
      if @_filter and @_filter.provider isnt item.getData().provider
        @handleClearFilter()

    list.on 'ItemDeleted', => @emit Events.CredentialListUpdated

    list.on Events.CredentialFilterChanged, (provider) =>

      return  if provider and not @selectionView.hasClass 'hidden'

      @_filter = null
      @_filter = { provider }  if provider

      @selectionView.setData @_filter

      if @_filter
      then @selectionView.show()
      else @selectionView.hide()

      @selectionView.click = @bound 'handleClearFilter'

      @filterByProvider @_filter



  showLazyLoader: ->

    super

    @getView().emit Events.LazyLoadStarted


  hideLazyLoader: ->

    super

    @getView().emit Events.LazyLoadFinished


  addListItems: (items) ->

    super items

    @emit Events.CredentialListUpdated


  showAddCredentialFormFor: (provider) ->

    view = super provider
    view.setClass 'has-markdown'

    @selectionView.setData { provider }
    @selectionView.show()

    @selectionView.click = (event) ->
      view.form.emit 'Cancel'
      kd.utils.stopDOMEvent event

    view.form.on 'KDObjectWillBeDestroyed', =>
      if @_filter
        @selectionView.setData @_filter
        @selectionView.click = @bound 'handleClearFilter'
      else
        @selectionView.hide()

    return view


  handleClearFilter: (event) ->

    @getListView().emit Events.CredentialFilterChanged
    @_filter = null
    kd.utils.stopDOMEvent event
