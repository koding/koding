kd                   = require 'kd'
KDView               = kd.View
KDModalView          = kd.ModalView
KDTabPaneView        = kd.TabPaneView
KDCustomHTMLView     = kd.CustomHTMLView
KDTabHandleContainer = kd.TabHandleContainer

Machine                      = require 'app/providers/machine'
MachineSettingsSpecsView     = require './machinesettingsspecsview'
MachineSettingsGuidesView    = require './machinesettingsguidesview'
MachineSettingsGeneralView   = require './machinesettingsgeneralview'
MachineSettingsDomainsView   = require './machinesettingsdomainsview'
MachineSettingsModalTabView  = require './machinesettingsmodaltabview'
MachineSettingsAdvancedView  = require './machinesettingsadvancedview'
MachineSettingsDiskUsageView = require './machinesettingsdiskusageview'
MachineSettingsVMSharingView = require './machinesettingsvmsharingview'
MachineSettingsSnapshotsView = require './machinesettingssnapshotsview'

OnboardingEvent = require 'app/onboarding/onboardingevent'

PANE_CONFIG = [
  { title: 'General',       viewClass: MachineSettingsGeneralView   }
  { title: 'Specs',         viewClass: MachineSettingsSpecsView     }
  { title: 'Disk Usage',    viewClass: MachineSettingsDiskUsageView }
  { title: 'Domains',       viewClass: MachineSettingsDomainsView   }
  { title: 'VM Sharing',    viewClass: MachineSettingsVMSharingView }
  { title: 'Snapshots',     viewClass: MachineSettingsSnapshotsView }
  { title: 'Advanced',      viewClass: MachineSettingsAdvancedView  }
  { title: 'Common guides', viewClass: MachineSettingsGuidesView    }
]


module.exports = class MachineSettingsModal extends KDModalView

  constructor: (options = {}, data) ->

    options.cssClass  = 'machine-settings-modal AppModal'
    options.title     = 'VM Settings'
    options.width     = 805
    options.height    = 445
    options.overlay  ?= yes

    super options, data

    @panesByTitle = {}

    @createTabView()
    @createPanes()
    @tweakStyling_()

    @tabView.showPaneByIndex 0

    kd.singletons.onboardingController.runOnboarding OnboardingEvent.VMSettingsOpened


  createTabView: ->

    tabHandleContainer = new KDTabHandleContainer cssClass: 'AppModal-nav'

    @addSubView tabHandleContainer

    @addSubView @tabView   = new MachineSettingsModalTabView
      hideHandleCloseIcons : yes
      maxHandleWidth       : 190
      tabHandleContainer   : tabHandleContainer

    tabHandleContainer.unsetClass 'kdtabhandlecontainer'


  createPanes: ->

    isMachineRunning = @getData().status.state is Machine.State.Running
    disabledTabs     = [ 'Disk Usage', 'Domains', 'VM Sharing' ]

    for item in PANE_CONFIG when item.title and item.viewClass

      subView    = new item.viewClass item.viewOptions, @getData()
      isDisabled = not isMachineRunning and disabledTabs.indexOf(item.title) > -1

      @tabView.addPane pane = new KDTabPaneView
        name     : item.title
        cssClass : 'AppModal-content'
        view     : subView
        disabled : isDisabled

      pane.tabHandle.setClass 'disabled'  if isDisabled
      subView.once 'ModalDestroyRequested', @bound 'destroy'

      @panesByTitle[item.title] = pane


  # MachineSettingsModal has same UI with AccountSettingsModal.
  # However to reuse ASM styling I needed to add/remove some classes.
  # We can consider this method later.
  tweakStyling_: ->

    for key, pane of @panesByTitle
      handle = pane.getHandle()
      handle.setClass   'AppModal-navItem' # styling
      handle.unsetClass 'kdtabhandle'      # styling
