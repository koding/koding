kd                    = require 'kd'
KDView                = kd.View
KDTabView             = kd.TabView
KDTabPaneView         = kd.TabPaneView
StackTabPaneView      = require './stacktabpaneview'
CredentialTabPaneView = require './credentialtabpaneview'


module.exports = class DefineStackTabView extends KDTabView


  constructor: (options = {}, data) ->

    options.hideHandleCloseIcons or= yes

    super options, data ? {}

    @addPane stack      = new KDTabPaneView name: 'Stack'
    @addPane credential = new KDTabPaneView name: 'Credential'

    stack.addSubView @stackView = new StackTabPaneView options, data
    credential.addSubView @credentialView = new CredentialTabPaneView

    @showPaneByIndex 0

    @stackView.on 'Cancel', => @emit 'Cancel'
