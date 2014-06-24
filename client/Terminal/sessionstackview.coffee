class SessionStackView extends KDView

  constructor: (options, data) ->

    options.tagName  = "ul"
    options.cssClass = "terminal-session-stack"

    super options, data

    { machine } = @getOptions()
    delegate    = @getDelegate()
    {@loader}   = delegate.startTab.machineWrapper[machine.uid]

    delegate.on "WebTermConnected",   @bound "updateSessions"
    delegate.on "TerminalClosed",     @bound "updateSessions"

    @updateSessions()


  updateSessions: ->

    @loader.show()

    { machine } = @getOptions()

    machine.getBaseKite().webtermGetSessions().then (sessions) =>

      @destroySubViews()
      @show()

      @loader.hide()
      sessions?.forEach @bound 'addSession'

      Metric.create "Sessions count", { count:sessions?.length }

    .catch (err) =>

      @hide()
      @loader.hide()

      unless (/no sessions available/i.test(err.message))
        KD.utils.warnAndLog "terminal: webtermGetSessions error",
          {reason:err?.message, machineId:@getOptions().machine.uid}


  addSession: (session, index) ->

    index++
    { machine, delegate } = @getOptions()

    @addSubView new SessionItemView {
      session, delegate, machine, index
    }
