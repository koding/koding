class CollaborativeClientTerminalPane extends Pane

  constructor: (options = {}, data) ->

    options.cssClass = "webterm client-webterm"

    super options, data

    @container = new KDView
      cssClass : "console ubuntu-mono green-on-black pane"

    panel           = @getDelegate()
    workspace       = panel.getDelegate()
    {@sessionKey}   = @getOptions()

    log "i am a client fake terminal and my session key is #{@sessionKey}"

    @workspaceRef = workspace.firepadRef.child @sessionKey

    @workspaceRef.on "value", (snapshot) =>
      encoded = snapshot.val()?.terminal
      return  unless encoded

      @container.updatePartial JSON.parse(window.atob(encoded)).join "<br />"

  pistachio: ->
    """
      {{> @container}}
    """