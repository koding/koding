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

    @previewer.on "ViewerRefreshed",       => @saveUrl yes

    @workspaceRef.on "value", (snapshot)   => @openPathFromSnapshot snapshot

  openPathFromSnapshot: (snapshot) ->
    value = snapshot.val()
    return unless value
    @previewer.openPath value.url  if value.url
    @previewPane.secureInfo?.destroy()

  openUrl: (url) ->
    @previewer.openPath url
    @saveUrl yes

  saveUrl: (force) ->
    {path} = @previewer
    url    = unless force then path.replace(/\?.*/, "") else "#{path}?#{Date.now()}"

    @workspaceRef.child("url").set url
    @workspace.addToHistory
      message: "$0 opened #{url}"
      by     : KD.nick()


class CollaborativePreview extends PreviewPane

  useHttp: ->
    super

    workspace  = @getDelegate().workspace
    sessionKey = workspace.sessionKey
    appName    = workspace.getOptions().name

    window.open "http://#{location.hostname}/#{appName}?sessionKey=#{sessionKey}"
