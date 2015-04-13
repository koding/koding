kd               = require 'kd'
KDView           = kd.View
KDTabView        = kd.TabView
KDModalView      = kd.ModalView
KDTabPaneView    = kd.TabPaneView
KDCustomHTMLView = kd.CustomHTMLView

MachineSettingsSpecsView     = require './machinesettingsspecsview'
MachineSettingsGuidesView    = require './machinesettingsguidesview'
MachineGeneralSettingsView   = require './machinegeneralsettingsview'
MachineSettingsAdvancedView  = require './machinesettingsadvancedview'
MachineSettingsDiskUsageView = require './machinesettingsdiskusageview'

PANE_CONFIG = [
  { title: 'General',       viewClass: MachineGeneralSettingsView   }
  { title: 'Specs',         viewClass: MachineSettingsSpecsView     }
  { title: 'Disk Usage',    viewClass: MachineSettingsDiskUsageView }
  { title: 'Domains',       viewClass: KDView                       }
  { title: 'VM Sharing',    viewClass: KDView                       }
  { title: 'Advanced',      viewClass: MachineSettingsAdvancedView  }
  { title: 'Common guides', viewClass: MachineSettingsGuidesView    }
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

      subView = new item.viewClass item.viewOptions, @getData()
      subView.once 'ModalDestroyRequested', @bound 'destroy'

      @tabView.addPane pane = new KDTabPaneView
        name     : item.title
        cssClass : 'AppModal-content'
        view     : subView

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
