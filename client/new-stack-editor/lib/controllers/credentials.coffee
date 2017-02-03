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

    self = this
    @listController.showLazyLoader = ->
      AccountCredentialListController::showLazyLoader.call this
      self.emit Events.LazyLoadStarted

    @listController.hideLazyLoader = ->
      AccountCredentialListController::hideLazyLoader.call this
      self.emit Events.LazyLoadFinished

  setData: (stackTemplate) ->

    super stackTemplate

    identifiers = stackTemplate.getCredentialIdentifiers()
    @list.items.forEach (item) ->
      item.select item.getData().identifier in identifiers
