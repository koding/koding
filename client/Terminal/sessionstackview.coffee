class SessionStackView extends KDView

  constructor: (options, data) ->

    super options, data

    @loader = new KDLoaderView
      size          : width : 16
      showLoader    : yes
      loaderOptions :
        color       : '#ffffff'

    {delegate} = @getOptions()
    @sessions = new KDCustomHTMLView
      tagName : "ul"

    delegate.on "WebTermConnected", @bound "updateSessions"
    delegate.on "TerminalClosed",   @bound "updateSessions"

    @updateSessions()

  updateSessions: ->
    @loader.show()
    {kite} = @getOptions()
    kite.webtermGetSessions().then (sessions) =>
      @sessions.destroySubViews()
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
    #{alias.replace 'koding.kd.io', 'kd.io'}
    {{> @loader }}
    {{> @sessions }}
    """


  viewAppended: JView::viewAppended


  addSession: (session, index)->
    {vm, delegate} = @getOptions()
    @sessions.addSubView new SessionItemView {session, delegate, vm, index: index + 1}
