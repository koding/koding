kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView
CustomLinkView = require 'app/customlinkview'
SidebarMachineBox = require './sidebarmachinebox'


module.exports = class SidebarMachineList extends KDCustomHTMLView

  constructor: (options = {}, data) ->

    options.tagName        = 'section'
    options.title        or= ''
    options.cssClass       = kd.utils.curry 'vms', options.cssClass
    options.hasPlusIcon   ?= no

    super options, data

    @machineBoxes = []
    @machineBoxesByMachineUId = {}

    @createHeader()
    @addMachineBoxes()


  createHeader: ->

    { title, hasPlusIcon } = @getOptions()

    @header = new KDCustomHTMLView
      tagName  : 'h3'
      cssClass : 'sidebar-title'
      partial  : title
      click    : => @emit 'ListHeaderClicked'

    if hasPlusIcon
      @header.addSubView new CustomLinkView
        cssClass : 'add-icon buy-vm'
        title    : ' '
        click    : (e) =>
          kd.utils.stopDOMEvent e
          @emit 'ListHeaderPlusIconClicked'

    @addSubView @header


  addMachineBoxes: ->

    for machineData in @getData()
      @addMachineBox machineData


  addMachineBox: (machineData) ->

    machineBox = new SidebarMachineBox {}, machineData
    @addSubView machineBox
    @machineBoxes.push machineBox
    @machineBoxesByMachineUId[machineData.machine.uid] = machineBox


  deselectMachines: ->

    @forEachMachineBoxes (box) ->
      box.unsetClass 'selected'


  selectMachineAndWorkspace: (machineUId, workspaceSlug) ->

    @forEachMachineBoxes (box) ->
      if box.machine.uid is machineUId
        box.setClass 'selected'
        box.selectWorkspace workspaceSlug
      else
        box.unsetClass 'selected'
        box.deselectWorkspaces()
        box.collapseList()


  forEachMachineBoxes: (callback) ->

    for box in @machineBoxes
      callback box


  deselectMachinesAndCollapseWorkspaces: ->

    @deselectMachines()
    @forEachMachineBoxes (box) ->
      box.deselectWorkspaces()
      box.collapseList()


  updateList: (listData) ->

    for data in listData
      unless @machineBoxesByMachineUId[data.machine.uid]
        @addMachineBox data
