class SessionStackView extends KDView

  constructor: (options, data) ->

    options.tagName  = "ul"
    options.cssClass = "terminal-session-stack"

    super options, data

    {alias}   = @getOptions()
    delegate  = @getDelegate()
    {@loader} = delegate.startTab.vmWrapper[alias]

    delegate.on "WebTermConnected", @bound "updateSessions"
    delegate.on "TerminalClosed",   @bound "updateSessions"

    @updateSessions()


  updateSessions: ->

    @loader.show()
    {kite} = @getOptions()
    kite.webtermGetSessions().then (sessions) =>
      @destroySubViews()
      @show()
      @loader.hide()
      Metric.create "Sessions count", {count:sessions.length}
      sessions?.forEach @bound 'addSession'
    .catch (err) =>
      @hide()
      @loader.hide()

      unless (/No sessions available/.test(err.message))
        KD.utils.warnAndLog "terminal: webtermGetSessions error",
          {reason:err.message, hostnameAlias:@getOptions().alias}

  addSession: (session, index) ->

    {vm, delegate} = @getOptions()
    index++
    @addSubView new SessionItemView {session, delegate, vm, index}
