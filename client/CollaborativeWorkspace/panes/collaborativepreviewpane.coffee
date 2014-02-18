class CollaborativePreviewPane extends CollaborativePane

  constructor: (options = {}, data) ->

    super options, data

    paneOptions = @getOptions()
    paneOptions.delegate = this

    @container.addSubView @previewPane = new CollaborativePreview paneOptions

    {@previewer} = @previewPane

    if @isJoinedASession
      @workspaceRef.once "value", (snapshot) =>
        @openPathFromSnapshot snapshot

    @previewer.on "ViewerLocationChanged", =>
      @saveUrl()
      @previewPane.secureInfo?.destroy()
      @sameOriginMessage?.destroy()

    @previewer.on "ViewerRefreshed",       => @saveUrl yes

    @workspaceRef.on "value", (snapshot)   => @openPathFromSnapshot snapshot

  openPathFromSnapshot: (snapshot) ->
    value = @workspace.reviveSnapshot snapshot

    if value?.url
      @recreateIframe()
      @previewer.openPath value.url
      @checkSameOrigin value.url
      @previewPane.secureInfo?.destroy()
      @sameOriginMessage?.destroy()

  openUrl: (url) ->
    @recreateIframe()
    @previewer.openPath url
    @saveUrl yes

  recreateIframe: ->
    @previewer.iframe.destroy()
    @previewer.createIframe()

  saveUrl: (force) ->
    {path} = @previewer
    url    = unless force then path.replace(/\?.*/, "") else "#{path}?#{Date.now()}"

    @workspaceRef.child("url").set url
    @checkSameOrigin url
    @workspace.addToHistory
      message: "$0 opened #{url}"
      by     : KD.nick()

  checkSameOrigin: (url) ->
    $.ajax
      type    : "GET"
      url     : "https://ssl.koding.com/#{url}"
      success : (responseCode) =>
        @createSameOriginMessage url  if responseCode.trim() is "0"

  createSameOriginMessage: (url) ->
    @sameOriginMessage?.destroy()
    @sameOriginMessage = new KDCustomHTMLView
      partial   : "<span>Unfortunately, the site you're trying to preview doesn't allow us to show its content here, </span>"
      cssClass  : "tw-browser-splash"

    @sameOriginMessage.addSubView new KDCustomHTMLView
      tagName   : "a"
      partial   : "click here"
      click     : -> window.open url.replace /\?.*/, ""

    @sameOriginMessage.addSubView new KDCustomHTMLView
      tagName   : "span"
      partial   : " to open in a new browser tab"

    @previewPane.container.addSubView @sameOriginMessage

  viewAppended: ->
    super

    # TODO: Find a better way without wait
    KD.utils.wait 200, =>
      @previewer.viewerHeader.pageLocation.getDomElement().focus()


class CollaborativePreview extends PreviewPane

  useHttp: ->
    super

    workspace  = @getDelegate().workspace
    sessionKey = workspace.sessionKey
    appName    = workspace.getOptions().name

    window.open "http://#{location.hostname}/#{appName}?sessionKey=#{sessionKey}"
