class IDE.PreviewPane extends IDE.Pane

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry 'preview-pane', options.cssClass
    options.paneType = 'preview'

    super options, data

    viewerOptions =
      delegate    : this
      params      :
        path      : @getOptions().url

    delete viewerOptions.params.path  unless viewerOptions.params.path

    @addSubView @previewer = new PreviewerView viewerOptions

    @previewer.on 'ViewerLocationChanged', (newLocation) =>
      @setOption 'url', newLocation
      @emit 'LocationChanged', newLocation
