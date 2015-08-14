kd                              = require 'kd'
curryIn                         = require 'app/util/curryIn'

CredentialListItem              = require 'app/stacks/credentiallistitem'
AccountCredentialList           = require 'account/accountcredentiallist'
AccountCredentialListController = require 'account/views/accountcredentiallistcontroller'


module.exports = class CredentialListView extends kd.View

  constructor: (options = {}, data) ->

    curryIn options, cssClass: 'stacks step-creds'

    super options, data

    { stackTemplate, selectedCredentials } = @getOptions()

    @list           = new AccountCredentialList {
      itemClass     : CredentialListItem
      itemOptions   : { stackTemplate }
      selectedCredentials
    }

    @listController = new AccountCredentialListController
      view          : @list
      wrapper       : no
      scrollView    : no

    @listView = @listController.getView()


  viewAppended: ->

    @addSubView @listView
