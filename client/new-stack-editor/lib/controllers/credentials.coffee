kd = require 'kd'
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


  setData: (data) ->

    super data

    @list.setOption 'stackTemplate', data
