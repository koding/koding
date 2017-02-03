kd = require 'kd'
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
      showCredentialMenu: no
      limit: 15
      view: @list

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

    self = this
    @listController.showLazyLoader = ->
      AccountCredentialListController::showLazyLoader.call this
      self.emit Events.LazyLoadStarted

    @listController.hideLazyLoader = ->
      AccountCredentialListController::hideLazyLoader.call this
      self.emit Events.LazyLoadFinished

    @list.on Events.CredentialSelectionChanged, =>
      if @isSelectionChanged()
      then @list.setClass 'has-change'
      else @list.unsetClass 'has-change'


  setData: (stackTemplate) ->

    super stackTemplate

    @updateCredentialSelections()


  updateCredentialSelections: ->

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
      @setData updatedTemplate
