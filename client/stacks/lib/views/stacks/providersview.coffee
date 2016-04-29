kd                  = require 'kd'
KDView              = kd.View
CredentialListView  = require './credentiallistview'


module.exports = class ProvidersView extends KDView


  constructor: (options = {}, data) ->

    super options, data

    { stackTemplate, selectedCredentials, provider, listItemClass } = @getOptions()

    @credentialList = new CredentialListView {
      stackTemplate, selectedCredentials, provider, listItemClass
    }

    @forwardEvents @credentialList.list, ['ItemSelected', 'ItemDeleted']

    mainView = @addSubView new KDView
      cssClass: 'stacks stacks-v2'

    mainView.addSubView @credentialList

  resetItems: ->
    @credentialList.list.emit 'ResetInuseStates'
