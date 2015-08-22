kd                    = require 'kd'
KDView                = kd.View
KDTabView             = kd.TabView
KDTabPaneView         = kd.TabPaneView
StackView             = require './stackview'
CredentialView        = require './credentialview'
curryIn               = require 'app/util/curryIn'


module.exports = class DefineStackTabView extends KDTabView


  constructor: (options = {}, data) ->

    curryIn options, cssClass: 'admin-stack'

    options.hideHandleCloseIcons or= yes

    super options, data ? {}

    @addPane stack      = new KDTabPaneView name: 'Stack Template'
    @addPane credential = new KDTabPaneView name: 'Private Credentials'

    stack.addSubView @stackView           = new StackView options, data
    credential.addSubView @credentialView = new CredentialView

    @showPaneByIndex 0

    @stackView.on 'Cancel', => @emit 'Cancel'
