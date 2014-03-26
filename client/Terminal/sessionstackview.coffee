class SessionStackView extends KDView

  constructor: (options, data) ->

    super options, data

    @loader = new KDLoaderView
      size          : width : 16
      showLoader    : yes
      loaderOptions :
        color       : '#ffffff'

    {kite} = @getOptions()
    @sessions = new KDCustomHTMLView
      tagName : "ul"
    kite.webtermGetSessions().then (sessions) =>
      @loader.hide()
      sessions.forEach (session, index) => @addSession session, index
    .catch (err) =>
      @loader.hide()
      @addSubView new KDCustomHTMLView partial: "Sessions are not available"


  pistachio: ->
    {alias} = @getOptions()
    """
    #{alias}
    {{> @loader }}
    {{> @sessions }}
    """


  viewAppended: JView::viewAppended


  addSession: (session, index)->
    {vm, delegate} = @getOptions()
    @sessions.addSubView new SessionItemView {session, delegate, vm, index: index + 1}
