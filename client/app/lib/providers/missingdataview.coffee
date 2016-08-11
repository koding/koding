kd                              = require 'kd'
curryIn                         = require 'app/util/curryIn'

CustomDataListItem              = require 'app/stacks/customdatalistitem'
AccountCredentialList           = require 'app/views/credentiallist/accountcredentiallist'
AccountCredentialListController = require 'app/views/credentiallist/accountcredentiallistcontroller'


module.exports = class MissingDataView extends kd.View

  constructor: (options = {}, data) ->

    curryIn options, { cssClass: 'stacks step-creds missingdata-view' }

    super options, data


  viewAppended: ->

    { stack, requiredFields, defaultTitle } = @getOptions()

    defaultTitle     ?= "#{stack.title} build requirements"

    @list             = new AccountCredentialList
      itemClass       : CustomDataListItem

    @listController   = new AccountCredentialListController {
      noItemFoundText : "You don't have a proper data document for
                         this stack. Please create a new one."
      view            : @list
      wrapper         : no
      scrollView      : no
      provider        : 'userInput'
      requiredFields
      defaultTitle
    }

    @credentialList = @listController.getView()

    @credentialList.on 'ItemSelected', (credential) =>

      { credentials } = stack
      credentials.userInput ?= []
      credentials.userInput.push credential.identifier

      stack.modify { credentials }, (err) =>
        kd.warn err  if err

        stack.credentials = credentials
        @emit 'RequirementsProvided', { stack, credential }


    @addSubView new kd.View
      partial: 'Based on the Stack Template which this Stack generated,
                you first need to provide some information to build
                this stack properly.'

    mainView = @addSubView new kd.View
      cssClass: 'stacks stacks-v2'

    mainView.addSubView @credentialList
