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

    return no  if @machineBoxesByMachineUId[machineData.uid]

    machineBox = new SidebarMachineBox {}, machineData
    @addSubView machineBox
    @machineBoxes.push machineBox
    @machineBoxesByMachineUId[machineData.machine.uid] = machineBox

    @show() if @machineBoxes.length is 1

    machineBox.once 'KDObjectWillBeDestroyed', =>
      @machineBoxes.splice @machineBoxes.indexOf(machineBox), 1
      delete @machineBoxesByMachineUId[machineBox.machine.uid]
      @emit 'MachineBoxDestroyed', machineBox


  removeWorkspaceByChannelId: (channelId) ->

    @forEachMachineBoxes (box) ->
      {workspaces} = box.getData()
      for workspace in workspaces when workspace
        if workspace.channelId is channelId
          return box.removeWorkspace workspace.getId()


  deselectMachines: ->

    @forEachMachineBoxes (box) -> box.deselect()


  selectMachineAndWorkspace: (machineUId, workspaceSlug) ->

    @forEachMachineBoxes (box) ->
      if box.machine.uid is machineUId
        box.select()
        box.selectWorkspace workspaceSlug
      else
        box.deselect()


  forEachMachineBoxes: (callback) ->

    for box in @machineBoxes
      callback box


  updateList: (listData) ->

    for data in listData
      unless @machineBoxesByMachineUId[data.machine.uid]
        @addMachineBox data
