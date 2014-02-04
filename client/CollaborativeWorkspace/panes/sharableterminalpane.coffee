class SharableTerminalPane extends TerminalPane

  constructor: (options = {}, data) ->

    super options, data

    @panel      = @getDelegate()
    @workspace  = @panel.getDelegate()
    @sessionKey = "dummy-#{KD.utils.getRandomNumber 100}" # dummy key, real key will be set when webterm connected

  createWebTermView: ->
    @webterm           = new WebTermView
      delegate         : this
      cssClass         : "webterm"
      mode             : "create"
      advancedSettings : no

  onWebTermConnected: ->
    super

    keysRef = @workspace.workspaceRef.child "keys"

    keysRef.once "value", (snapshot) =>
      keyChain = @workspace.reviveSnapshot snapshot
      keys     = keyChain[@workspace.lastCreatedPanelIndex]

      for key, index in keys when key is @sessionKey
        @sessionKey =
          key       : @remote.session
          host      : KD.nick()
          vmName    : KD.getSingleton("vmController").defaultVmName

        keys[index] = @sessionKey

      keysRef.set keyChain