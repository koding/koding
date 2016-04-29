kd                              = require 'kd'
curryIn                         = require 'app/util/curryIn'

CredentialListItem              = require 'app/stacks/credentiallistitem'
AccountCredentialList           = require 'account/accountcredentiallist'
AccountCredentialListController = require 'account/views/accountcredentiallistcontroller'


module.exports = class CredentialListView extends kd.View

  constructor: (options = {}, data) ->

    curryIn options, { cssClass: 'stacks step-creds' }

    super options, data

    { stackTemplate, selectedCredentials, provider, listItemClass } = @getOptions()

    @list           = new AccountCredentialList {
      itemClass     : listItemClass or CredentialListItem
      itemOptions   : { stackTemplate }
      selectedCredentials
    }

    @listController = new AccountCredentialListController {
      view                 : @list
      limit                : 15
      useCustomScrollView  : yes
      lazyLoadThreshold    : 15
      provider
    }

    @listView = @listController.getView()


  viewAppended: ->

    @addSubView @listView
