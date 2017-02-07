kd = require 'kd'
JView = require 'app/jview'
Events = require '../events'
BaseController = require './base'

CredentialListItem              = require '../views/credentiallistitem'
AccountCredentialList           = require 'app/views/credentiallist/accountcredentiallist'
AccountCredentialListController = require 'app/views/credentiallist/accountcredentiallistcontroller'


module.exports = class CredentialsController extends BaseController


  constructor: (options = {}, data) ->

    super options, data

    @list = new AccountCredentialList
      itemClass: CredentialListItem

    @listController = new AccountCredentialListController
      limit      : 15
      view       : @list
      baseQuery  :
        provider : { $ne: 'custom' }

    @listView = @listController.getView()

    statusView = @list.addSubView new kd.CustomHTMLView
      cssClass : 'status-view'

    statusView.addSubView new kd.ButtonView
      cssClass : 'kdbutton action-button solid green compact save-button'
      callback : @bound 'handleSaveChanges'
      title    : 'Save Changes'

    statusView.addSubView new kd.ButtonView
      cssClass : 'kdbutton action-button solid gray compact revert-button'
      callback : @bound 'handleRevertChanges'
      title    : 'Revert Changes'

    @filterView  = @listView.addSubView new JView
      cssClass   : 'filter-view hidden'
      pistachio  : '''
        Currently selected provider: <b>{{#(provider)}}</b> <cite />
      '''
      click      : (event) =>
        @list.emit Events.CredentialFilterChanged
        kd.utils.stopDOMEvent event
    , { provider : '' }

    self = this
    @listController.showLazyLoader = ->
      AccountCredentialListController::showLazyLoader.call this
      self.emit Events.LazyLoadStarted

    @listController.hideLazyLoader = ->
      AccountCredentialListController::hideLazyLoader.call this
      self.emit Events.LazyLoadFinished

    @listController.addListItems = (items) ->
      AccountCredentialListController::addListItems.call this, items
      self.updateCredentialSelections()


    @list.on Events.CredentialSelectionChanged, =>

      if @isSelectionChanged()
      then @list.setClass 'has-change'
      else @list.unsetClass 'has-change'


    @list.on Events.CredentialFilterChanged, (provider) =>

      return  if provider and not @filterView.hasClass 'hidden'

      filter = null
      filter = { provider }  if provider

      @filterView.setData filter

      if filter
      then @filterView.show()
      else @filterView.hide()

      @listController.filterByProvider filter


  setData: (stackTemplate, internal = no) ->

    super stackTemplate

    if not internal and not @filterView.hasClass 'hidden'
      @filterView.hide()
      @listController.filterByProvider()
    else
      @updateCredentialSelections()


  updateCredentialSelections: ->

    return  unless @getData()

    identifiers = @getData().getCredentialIdentifiers()
    @list.items.forEach (item) ->
      item.select item.getData().identifier in identifiers

    @list.unsetClass 'has-change'


  isSelectionChanged: ->

    identifiers = @getData().getCredentialIdentifiers()
    for item in @list.items
      inIdentifiers = item.getData().identifier in identifiers
      isSelected = item.isSelected()
      return yes  if (isSelected and not inIdentifiers) or \
                     (not isSelected and inIdentifiers)

    return no


  getSelectedCredentials: ->

    credentials = {}
    for item in @list.items when item.isSelected()
      credential = item.getData()
      credentials[credential.provider] ?= []
      credentials[credential.provider].push credential.identifier

    return credentials


  handleRevertChanges: CredentialsController::updateCredentialSelections


  handleSaveChanges: ->

    credentials   = @getSelectedCredentials()
    stackTemplate = @getData()

    stackTemplate.update { credentials }, (err, updatedTemplate) =>
      return @logs.handleError err  if err

      @logs.add 'Stack template updated successfully!'
      @setData updatedTemplate, internal = yes
