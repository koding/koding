kd                              = require 'kd'
curryIn                         = require 'app/util/curryIn'

CredentialListItem              = require 'app/stacks/credentiallistitem'
AccountCredentialList           = require 'account/accountcredentiallist'
AccountCredentialListController = require 'account/views/accountcredentiallistcontroller'


module.exports = class MissingDataView extends kd.View

  constructor: (options = {}, data) ->

    curryIn options, cssClass: 'stacks step-creds'

    super options, data


  viewAppended: ->

    { stackTemplate, selectedCredentials } = @getOptions()

    @list           = new AccountCredentialList {
      itemClass     : CredentialListItem
      itemOptions   : { stackTemplate }
      selectedCredentials
    }

    { requiredFields, defaultTitle } = @getOptions()

    @listController   = new AccountCredentialListController {
      view            : @list
      wrapper         : no
      scrollView      : no
      provider        : 'custom'
      requiredFields
      defaultTitle
    }

    @credentialList = @listController.getView()

    @forwardEvent @credentialList, 'ItemSelected'

    mainView = @addSubView new kd.View
      cssClass: 'stacks stacks-v2'

    mainView.addSubView @credentialList
