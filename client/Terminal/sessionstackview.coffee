class SessionStackView extends KDView

  constructor: (options, data) ->

    options.tagName  = "ul"
    options.cssClass = "terminal-session-stack"

    super options, data

    @loader = new KDLoaderView
      size          : width : 16
      showLoader    : yes
      loaderOptions :
        color       : '#ffffff'

    {delegate} = @getOptions()

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
      sessions.forEach (session, index) => @addSession session, index
    .catch (err) =>
      @hide()
      @loader.hide()
      warn err  unless err.code is "ErrNoSession"


  pistachio: ->
    {alias} = @getOptions()
    """
    {{> @loader }}
    {{> @sessions }}
    """


  viewAppended: JView::viewAppended

  addSession: (session, index) ->

    {vm, delegate} = @getOptions()
    index++
    @addSubView new SessionItemView {session, delegate, vm, index}
