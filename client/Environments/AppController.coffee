class EnvironmentsAppController extends AppController

  KD.registerAppClass this,
    name         : "Environments"
    route        : "/:name?/Environments"
    hiddenHandle : yes
    behavior     : "application"
    # navItem      :
    #   title      : "Environments"
    #   path       : "/Environments"
    #   role       : "member"
    commands     :
      'clear buffer'  : -> console.log 'clearing the buffer'
      'ring bell'     : -> console.log 'ringing the bell'
      'noop'          : -> console.log 'not doing shiiiit'
    keyBindings  : [
      { command: 'clear buffer',  binding: 'super+k' }
      { command: 'ring bell',     binding: 'alt+super+k' }
      { command: 'noop',          bindings: ['super+v','super+r'] }
    ]

  constructor:(options = {}, data)->

    options.view    = new EnvironmentsMainView
      cssClass      : "environments split-layout"
    options.appInfo =
      name          : "Environments"

    super options, data
