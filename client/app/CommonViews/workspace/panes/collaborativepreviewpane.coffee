class CollaborativePreviewPane extends CollaborativePane

  constructor: (options = {}, data) ->

    super options, data

    @container.addSubView @previewPane = new PreviewPane @getOptions()

    {@previewer} = @previewPane

    if @isJoinedASession
      @workspaceRef.once "value", (snapshot) => @openPath snapshot
    else
      @previewer.on "ready", => @saveUrl()

    @previewer.on "ViewerLocationChanged", => @saveUrl()

    @previewer.on "ViewerRefreshed",       => @saveUrl yes

    @workspaceRef.on "value", (snapshot)   => @openPath snapshot

    @workspaceRef.onDisconnect().remove() if @amIHost

  openPath: (snapshot) ->
    value = snapshot.val()
    @previewer.openPath value.url  if value?.url

  saveUrl: (force) ->
    url = unless force then @previewer.path.replace(/\?.*/, "") else "#{url}?#{Date.now()}"
    @workspaceRef.child("url").set url
