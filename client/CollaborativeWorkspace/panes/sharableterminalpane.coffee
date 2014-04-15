class SharableTerminalPane extends TerminalPane

  constructor: (options = {}, data) ->

    super options, data

    @panel      = @getDelegate()
    @workspace  = @panel.getDelegate()
    @sessionKey = "dummy-#{KD.utils.getRandomNumber 100}" # dummy key, real key will be set when webterm connected

  onWebTermConnected: ->
    super

    keysRef = @workspace.workspaceRef.child "keys"

    KD.getSingleton("vmController").fetchDefaultVm (err, vm)=>

      return warn err  if err

      keysRef.once "value", (snapshot) =>
        keyChain = @workspace.reviveSnapshot snapshot
        keys     = keyChain[@workspace.lastCreatedPanelIndex]

        for key, index in keys when key is @sessionKey
          @sessionKey =
            key       : @remote.session
            host      : KD.nick()
            vmName    : vm.hostnameAlias
            vmRegion  : vm.region

          keys[index] = @sessionKey

        keysRef.set keyChain
