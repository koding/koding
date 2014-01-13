class BugReportMainView extends KDScrollView

  constructor:(options = {}, data)->
    super options, data

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
        @emit "ChangeFilterClicked", "all"

    @inputWidget = new ActivityInputWidget
      app        : 'bug'

    @inputWidget.on "Submit", (err, activity)=>
      return err if err
      lists = @getDelegate().feedController.resultsController.listControllers
      lists.all.addItem activity, 0

    groupController = KD.getSingleton("groupsController")
    groupController.on "PostIsCreated", (post) =>
      subject = @prepareSubject post
      if subject.feedType is "bug"
        lists = @getDelegate().feedController.resultsController.listControllers
        lists.all.addItem subject, 0

  prepareSubject:(post)->
    {subject} = post
    return KD.remote.revive subject

  viewAppended:->
    @mainBlock = new KDCustomHTMLView tagName : "main"
    @sideBlock = new KDCustomHTMLView tagName : "aside"

    @addSubView @mainBlock
    @addSubView @sideBlock

    @mainBlock.addSubView @inputWidget
    @sideBlock.addSubView @filterMenu
