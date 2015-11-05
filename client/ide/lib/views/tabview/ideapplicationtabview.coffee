kd                  = require 'kd'
$                   = require 'jquery'
KDModalView         = kd.ModalView
KDTabView           = kd.TabView
IDETabHandleView    = require './idetabhandleview'
ApplicationTabView  = require 'app/commonviews/applicationview/applicationtabview'
SplitRegionView     = require './region/splitregionview'


module.exports = class IDEApplicationTabView extends ApplicationTabView


  constructor: (options = {}, data) ->

    options.sortable        ?= no
    options.droppable       ?= yes
    options.tabHandleClass   = IDETabHandleView
    options.bind             = 'dragenter'

    super options, data


  removePane_: KDTabView::removePane

  removePane: (pane, shouldDetach, quiet = no) ->

    return  unless pane

    { aceView } = pane.getOptions()

    if quiet or not aceView or not aceView.ace.isContentChanged()
      return @removePane_ pane, shouldDetach

    @askForSave pane, aceView


  askForSave: (pane, aceView) ->

    content = "Your changes will be lost if you don't save them. "

    { frontApp } = kd.singletons.appManager

    frontApp.checkSessionActivity
      active    : =>
        myWatchers = frontApp.getMyWatchers()

        content += @getMyWatchersContentForModal(myWatchers)  if myWatchers.length

        @showModal_ pane, aceView, content

      error      : => @showModal_ pane, aceView, content
      notStarted : => @showModal_ pane, aceView, content


  getMyWatchersContentForModal: (myWatchers) ->

    more = ""

    if myWatchers.length > 3
      more = " and <strong>#{myWatchers.length - 3}</strong> others"

    return """
      Also #{(myWatchers.slice(0,3).map (w) -> '<strong>@'+w+'</strong>').join(', ')}
      #{more} may have some changes here.
    """


  showModal_: (pane, aceView, content) ->

    { ace } = aceView
    file    = ace.getData()

    modal = new KDModalView
      width         : 620
      cssClass      : "modal-with-text"
      title         : "Do you want to save your changes?"
      content       : "<p>#{content}</p>"
      overlay       : yes
      buttons       :
        "SaveClose" :
          cssClass  : "solid green medium"
          title     : "Save and Close"
          callback  : =>
            if file.path.indexOf("localfile:") is 0
              file.once "fs.saveAs.finished", => @removePane_ pane
              @willClose = yes
              ace.requestSaveAs()
              modal.destroy()
            else
              ace.requestSave()
              file.once "fs.save.finished", => @removePane_ pane
              modal.destroy()
        "DontSave"  :
          cssClass  : "solid red medium"
          title     : "Don't Save"
          callback  : =>
            @closePaneAndModal pane, modal
        "Cancel"    :
          cssClass  : "solid light-gray medium"
          title     : "Cancel"
          callback  : =>
            modal.destroy()


  closePaneAndModal: (pane, modal) ->

    @removePane_ pane
    modal.destroy()


  dragEnter: (event) ->

    # frontApp references to IDEAppController
    { frontApp } = kd.singletons.appManager

    return  if @splitRegions

    # Return if there isn't any dragging tab.
    return  unless frontApp.targetTabView

    @addSubView @splitRegions = new SplitRegionView

    @splitRegions.on 'TabDropped', (direction) =>
      frontApp.handleTabDropToRegion direction, @parent


  removeSplitRegions: ->

    @splitRegions?.destroy()
    @splitRegions = null


  handleCloseAction: (pane) ->

    @emit 'PaneRemovedByUserAction', pane

    super pane

