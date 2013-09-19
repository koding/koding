class PreviewPane extends Pane

  constructor: (options = {}, data) ->

    options.cssClass = "preview-pane"

    super options, data

    @container    = new KDView
      cssClass    : "workspace-viewer"

    {url}         = @getOptions()
    viewerOptions =
      delegate    : this
      params      : {}

    viewerOptions.params.path = url  if url

    @container.addSubView @previewer = new PreviewerView viewerOptions

  pistachio: ->
    """
      {{> @header}}
      {{> @container}}
    """
