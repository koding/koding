kd                  = require 'kd'
KDModalView         = kd.ModalView
KDTabView           = kd.TabView
IDETabHandleView    = require './idetabhandleview'
ApplicationTabView  = require 'app/commonviews/applicationview/applicationtabview'
SplitRegionView     = require './region/splitregionview'
contentModal = require 'app/components/contentModal'

module.exports = class IDEApplicationTabView extends ApplicationTabView


  constructor: (options = {}, data) ->

    options.sortable        ?= no
    options.droppable       ?= yes
    options.tabHandleClass   = IDETabHandleView
    options.bind             = 'dragenter'

    super options, data


  removePane_: KDTabView::removePane


  removePane: (pane, shouldDetach, quiet = no, askforsave = yes) ->

    return  unless pane

    { aceView }        = pane.getOptions()
    { isFileReadonly } = pane.view

    if quiet or isFileReadonly or not aceView or not aceView.ace.isCurrentContentChanged() or not askforsave
      return @removePane_ pane, shouldDetach


    @askForSave pane, aceView  if askforsave

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
    , no


  getMyWatchersContentForModal: (myWatchers) ->

    more = ''

    if myWatchers.length > 3
      more = " and <strong>#{myWatchers.length - 3}</strong> others"

    return """
      Also #{(myWatchers.slice(0, 3).map (w) -> '<strong>@'+w+'</strong>').join(', ')}
      #{more} may have some changes here.
    """


  showModal_: (pane, aceView, content) ->

    { ace } = aceView
    file    = ace.getData()

    @askForSaveModal?.destroy()
    @askForSaveModal = new contentModal
      width         : 620
      cssClass      : 'modal-with-text content-modal'
      title         : 'Do you want to save your changes?'
      content       : "<h2>#{content}</h2>"
      overlay       : yes
      buttons       :
        'Cancel'    :
          cssClass  : 'solid cancel medium'
          title     : 'Cancel'
          callback  : =>
            @askForSaveModal.destroy()
        'SaveClose' :
          cssClass  : 'solid medium'
          title     : 'Save and Close'
          callback  : =>
            if file.isDummyFile()
              @willClose = yes
              ace.requestSaveAs()
            else
              ace.requestSave()

            file.once [ 'fs.saveAs.finished', 'fs.save.finished' ], =>
              @removePane_ pane
              @parent.handleCloseSplitView pane

            @askForSaveModal.destroy()
        'DontSave'  :
          cssClass  : 'solid medium'
          title     : "Don't Save"
          callback  : =>
            @removePane_ pane
            @parent.handleCloseSplitView pane
            @askForSaveModal.destroy()
            file.emit 'FileContentsNeedsToBeRefreshed'


  dragEnter: (event) ->

    # frontApp references to IDEAppController
    { frontApp } = kd.singletons.appManager

    return  if @splitRegions

    # Return if there is no dragging tab.
    return  unless frontApp.targetTabView

    @addSubView @splitRegions = new SplitRegionView

    @splitRegions.on 'TabDropped', (direction) =>
      frontApp.handleTabDropToRegion direction, @parent


  removeSplitRegions: ->

    @splitRegions?.destroy()
    @splitRegions = null


  handleCloseAction: (pane, emit = yes) ->

    super pane

    @emit 'PaneRemovedByUserAction', pane  if emit
