# class ContentDisplayControllerAbout extends KDViewController
#   constructor:(options = {}, data)->
#     options = $.extend
#       view : mainView = new KDView
#         cssClass : 'about content-display'
#     , options

#     super options, data

#   loadView:(mainView)->
#     @mainView = mainView
#     contentDisplayController = @getSingleton "contentDisplayController"

#     mainView.addSubView subHeader = new KDCustomHTMLView tagName : "h2", cssClass : 'sub-header'
#     subHeader.addSubView backLink = new KDCustomHTMLView tagName : "a", partial : "<span>&laquo;</span> Back"

#     mainView.addSubView aboutView = new AboutView
#       cssClass : "about-pane"
#       delegate : mainView
#     , @getData()

#     @listenTo
#       KDEventTypes : "click"
#       listenedToInstance : backLink
#       callback : ()=>
#         contentDisplayController.emit "ContentDisplayWantsToBeHidden", mainView
