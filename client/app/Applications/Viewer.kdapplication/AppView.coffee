class PreviewerView extends KDView

  constructor:(options = {},data)->

    options.cssClass = 'previewer-body'

    super options, data

  openPath:(path)->

    # do not open main koding domains in the iframe
    if /(^(http(s)?:\/\/)?beta\.|^(http(s)?:\/\/)?)koding\.com/.test path
      @viewerHeader.pageLocation.setClass "validation-error"
      return

    realPath = unless /^http(s)?:\/\//.test path then "http://#{path}" else path
    cacheBusterPath = "#{realPath}?#{Date.now()}"

    @path = realPath
    @iframe.$().attr 'src', cacheBusterPath
    @viewerHeader.setPath realPath

  refreshIFrame:-> @iframe.$().attr 'src', @path

  viewAppended:->

    @addSubView @viewerHeader = new ViewerTopBar {}, @path
    @addSubView @iframe       = new KDCustomHTMLView tagName : 'iframe'
