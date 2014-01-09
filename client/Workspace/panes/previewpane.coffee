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

    @container.addSubView new KDCustomHTMLView
      tagName  : "p"
      cssClass : "tw-browser-splash"
      partial  : """ Sorry, you can only preview links starting with "https" """

  pistachio: ->
    """
      {{> @header}}
      {{> @container}}
    """
