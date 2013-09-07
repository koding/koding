class CollaborativePreviewPane extends CollaborativePane

  constructor: (options = {}, data) ->

    super options, data

    @container.addSubView @previewPane = new PreviewPane @getOptions()

    {@previewer} = @previewPane

    if @isJoinedASession
      @workspaceRef.once "value", (snapshot) =>
        @previewer.openPath snapshot.val().url
    else
      @previewer.on "ready", => @saveUrl()

    @previewer.on "ViewerLocationChanged", => @saveUrl()

    @previewer.on "ViewerRefreshed",       => @saveUrl yes

    @workspaceRef.on "value", (snapshot)   =>
      @previewer.openPath snapshot.val().url

    @workspaceRef.onDisconnect().remove() if @amIHost

  saveUrl: (force) ->
    url = @previewer.path.replace /\?.*/, ""
    @workspaceRef.child("url").set if force then "#{url}?#{Date.now()}" else url
