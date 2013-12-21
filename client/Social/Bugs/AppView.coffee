class BugReportMainView extends KDScrollView

  constructor:(options = {}, data)->
    super options, data

    {@delegate} = @getOptions()

    @filterMenu = new KDCustomHTMLView
      cssClass      : "bug-status right-block-box"

    filterOptions = [
        { title : "all"       , value : "all"       }
        { title : "fixed"     , value : "fixed"     }
        { title : "changelog" , value : "changelog" }
      ]

    @filterMenu.addSubView new KDCustomHTMLView
      tagName  : "a"
      cssClass : "bug-status-title"
      partial  : "Bug Reports"
      click    : =>
        @delegate.emit "ChangeFilterClicked", "all"

    @filterMenu.addSubView new KDCustomHTMLView
      tagName  : "a"
      cssClass : "bug-status-title"
      partial  : "Fixed Bugs"
      click    : =>
        @delegate.emit "ChangeFilterClicked", "fixed"

    @filterMenu.addSubView new KDCustomHTMLView
      tagName  : "a"
      cssClass : "bug-status-title"
      partial  : "ChangeLog"
      click    : =>
        @delegate.emit "ChangeFilterClicked", "changelog"

    @inputWidget = new ActivityInputWidget

  viewAppended:->
    @mainBlock = new KDCustomHTMLView tagName : "main"
    @sideBlock = new KDCustomHTMLView tagName : "aside"

    @addSubView @mainBlock
    @addSubView @sideBlock

    @mainBlock.addSubView @inputWidget
    @sideBlock.addSubView @filterMenu

    KD.remote.api.JTag.one slug:"bug", (err, tag) =>
      @inputWidget.input.setDefaultTokens tags: [tag]
