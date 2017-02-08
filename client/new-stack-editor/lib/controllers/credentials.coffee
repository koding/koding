kd = require 'kd'
JView = require 'app/jview'
Events = require '../events'
BaseController = require './base'

StackCredentialListController = require './credentialslistcontroller'


module.exports = class CredentialsController extends BaseController


  constructor: (options = {}, data) ->

    super options, data

    @listController = new StackCredentialListController

    @listController.on [
      Events.CredentialListUpdated
      Events.CredentialChangesRevertRequested
    ], @bound 'updateCredentialSelections'

    @listController.on Events.CredentialChangesSaveRequested, \
      @bound 'handleSaveChanges'

    @list = @listController.getListView()
    @list.on Events.CredentialSelectionChanged, =>

      if @isSelectionChanged()
      then @list.setClass 'has-change'
      else @list.unsetClass 'has-change'


  getView: -> @listController.getView()


  setData: (stackTemplate, internal = no) ->

    super stackTemplate

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


  handleSaveChanges: ->

    credentials   = @getSelectedCredentials()
    stackTemplate = @getData()

    stackTemplate.update { credentials }, (err, updatedTemplate) =>
      return @logs.handleError err  if err

      @logs.add 'Stack template updated successfully!'
      @setData updatedTemplate, internal = yes


  getCredentialAddButton: ->

    @listController._createAddCredentialMenuButton
      cssClass : 'plus'
      diff     :
        x      : -93
        y      : 12
