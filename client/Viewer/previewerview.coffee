class PreviewerView extends KDView

  constructor:(options = {},data)->

    options.cssClass = 'previewer-body'

    super options, data

  openPath:(path)->

    # do not open main koding domains in the iframe
    if /(^(https?:\/\/)?beta\.|^(https?:\/\/)?)koding\.com/.test path
      @viewerHeader.pageLocation.setClass "validation-error"
      return

    initialPath = path
    # put cachebuster timespan as the only param or
    # append to the existing parameters
    path += "#{if /\?/.test path then '&' else '?'}#{Date.now()}"
    # put http:// in front of the path if it's not given
    path  = unless /^https?:\/\//.test path then "http://#{path}" else path

    @path = path
    @iframe.setAttribute 'src', path
    @viewerHeader.setPath initialPath
    @emit "ready"

  refreshIFrame:->
    @iframe.setAttribute 'src', "#{@path}"

  isDocumentClean:->
    @clean

  createIframe: ->
    @addSubView @iframe = new KDCustomHTMLView
      tagName : "iframe"

  viewAppended:->
    @addSubView @viewerHeader = new ViewerTopBar { delegate: this }, @path
    @createIframe()

    {params} = @getOptions()
    path     = params?.path
    if path then @utils.defer => @openPath path
