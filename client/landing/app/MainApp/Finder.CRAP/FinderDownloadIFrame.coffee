class FinderDownloadIFrame extends KDView
  constructor: ->
    super

    mainView.addSubView @
    
  setDomElement: ->
    @domElement = $ "<iframe src='#{@getOptions().url}' />"