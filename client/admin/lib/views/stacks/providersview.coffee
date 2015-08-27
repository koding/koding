kd                  = require 'kd'
KDView              = kd.View
KDCustomHTMLView    = kd.CustomHTMLView
CredentialListView  = require './credentiallistview'


module.exports = class ProvidersView extends KDView


  constructor: (options = {}, data) ->

    super options, data

    @addSubView new KDCustomHTMLView
      cssClass  : 'text header'
      partial   : 'Select Credentials to use'

    { stackTemplate, selectedCredentials } = @getOptions()

    @credentialList = new CredentialListView {
      stackTemplate, selectedCredentials
    }

    @forwardEvent @credentialList.list, 'ItemSelected'

    mainView = @addSubView new KDView
      cssClass: 'stacks stacks-v2'

    mainView.addSubView @credentialList
