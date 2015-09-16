kd                  = require 'kd'
KDView              = kd.View
KDCustomHTMLView    = kd.CustomHTMLView
CredentialListView  = require './credentiallistview'


module.exports = class ProvidersView extends KDView


  constructor: (options = {}, data) ->

    super options, data

    @addSubView new KDCustomHTMLView
      cssClass  : 'text header'
      partial   : 'Provide credential details for this stack'

    { stackTemplate, selectedCredentials, provider } = @getOptions()

    @credentialList = new CredentialListView {
      stackTemplate, selectedCredentials, provider
    }

    @forwardEvent @credentialList.list, 'ItemSelected'

    mainView = @addSubView new KDView
      cssClass: 'stacks stacks-v2'

    mainView.addSubView @credentialList

  resetItems: ->
    @credentialList.list.emit 'ResetInuseStates'