kd               = require 'kd'
KDView           = kd.View
KDTabView        = kd.TabView
KDModalView      = kd.ModalView
KDTabPaneView    = kd.TabPaneView
KDCustomHTMLView = kd.CustomHTMLView


PANE_CONFIG = [
  {
    title       : 'General'
    viewClass   : KDView
    viewOptions : partial: 'General'
  }
  {
    title       : 'Advanced'
    viewClass   : KDView
    viewOptions : partial: 'Advanced'
  }
  {
    title       : 'Guides'
    viewClass   : KDView
    viewOptions : partial: 'Guides'
  }
  {
    title       : 'Domains'
    viewClass   : KDView
    viewOptions : partial: 'Domains'
  }
  {
    title       : 'Specs'
    viewClass   : KDView
    viewOptions : partial: 'Specs'
  }
  {
    title       : 'Disk Usage'
    viewClass   : KDView
    viewOptions : partial: 'Disk Usage'
  }
  {
    title       : 'Shared VM'
    viewClass   : KDView
    viewOptions : partial : 'Shared VM'
  }
]




module.exports = class MachineSettingsModal extends KDModalView

  constructor: (options = {}, data) ->

    options.cssClass = 'machine-settings-modal AppModal'
    options.title    = 'VM Settings'
    options.width    = 805

    super options, data

    @panesByTitle = {}

    @createTabView()
    @createPanes()
    @tweakStyling_()

    @tabView.showPaneByIndex 0


  createTabView: ->

    @addSubView @tabView   = new KDTabView
      hideHandleCloseIcons : yes
      maxHandleWidth       : 190


  createPanes: ->

    for item in PANE_CONFIG when item.title and item.viewClass

      @tabView.addPane pane = new KDTabPaneView
        name     : item.title
        cssClass : 'AppModal-content'
        view     : new item.viewClass item.viewOptions, item.viewData

      @panesByTitle[item.title] = pane


  # MachineSettingsModal has same UI with AccountSettingsModal.
  # However to reuse ASM styling I needed to add/remove some classes.
  # We can consider this method later.
  tweakStyling_: ->

    @tabView.tabHandleContainer.setClass 'AppModal-nav' # styling

    for key, pane of @panesByTitle
      handle = pane.getHandle()
      handle.setClass   'AppModal-navItem' # styling
      handle.unsetClass 'kdtabhandle'      # styling
