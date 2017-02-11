debug = (require 'debug') 'nse:controller:credentials'

kd = require 'kd'
_ = require 'lodash'
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

    @listController.on Events.CredentialChangesSaveRequested, => @save()

    @list = @listController.getListView()
    @list.on Events.CredentialSelectionChanged, =>

      if @isSelectionChanged()
      then @list.setClass 'has-change'
      else @list.unsetClass 'has-change'


  getView: -> @listController.getView()


  check: (callback) ->

    stackTemplate = @getData()
    selectedCredentials = @getSelectedCredentials()
    templateCredentials = stackTemplate.getCredentialProviders()

    if @isSelectionChanged() and _.size selectedCredentials
      @save selectedCredentials, callback
    else if templateCredentials.length is 0
      @emit Events.WarnAboutMissingCredentials
      callback { error: 'Missing Credentials' }
    else
      callback null


  setData: (stackTemplate) ->

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


  save: (credentials, callback = kd.noop) ->

    unless @isSelectionChanged()
      return callback null

    credentials  ?= @getSelectedCredentials()
    stackTemplate = @getData()

    if customVariables = stackTemplate.credentials.custom
      credentials.custom = customVariables

    stackTemplate.update { credentials }, (err, updatedTemplate) =>

      if err
        callback err
        @logs.handleError err
        return

      @logs.add 'Stack template updated successfully!'
      @emit Events.TemplateDataChanged, updatedTemplate
      callback null


  getCredentialAddButton: ->

    @listController._createAddCredentialMenuButton
      cssClass : 'plus'
      diff     :
        x      : -93
        y      : 12
