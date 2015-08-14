kd                 = require 'kd'
curryIn            = require 'app/util/curryIn'

CredentialListView = require './credentiallistview'


module.exports = class CredentialSelectorModal extends kd.ModalView

  constructor: (options = {}, data) ->

    curryIn options, cssClass: 'AppModal AppModal--admin'

    options.title        or= 'Select Credentials to use'
    options.overlay       ?= yes
    options.overlayOptions =
      cssClass             : 'second-overlay'
    options.width         ?= 630
    options.height         = '100%'

    super options, data


  viewAppended: ->

    { stackTemplate, selectedCredentials } = @getOptions()

    @credentialList = new CredentialListView {
      stackTemplate, selectedCredentials
    }

    @forwardEvent @credentialList.list, 'ItemSelected'

    mainView = @addSubView new kd.View
      cssClass: 'stacks stacks-v2'

    mainView.addSubView @credentialList
