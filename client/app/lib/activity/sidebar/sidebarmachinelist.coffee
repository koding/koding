kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView
CustomLinkView = require 'app/customlinkview'
SidebarMachineBox = require 'app/activity/sidebar/sidebarmachinebox'
MoreVMsModal = require 'app/activity/sidebar/morevmsmodal'


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
      click    : => new MoreVMsModal {}, @getMachines()

    if hasPlusIcon
      @header.addSubView new CustomLinkView
        cssClass : 'add-icon buy-vm'
        title    : ' '

    @addSubView @header


  addMachineBoxes: (boxes) ->

    data = boxes or @getData()

    for obj in data
      @addMachineBox obj


  addMachineBox: (machineAndWorkspaceData) ->

    { uid } = machineAndWorkspaceData.machine

    return no  if @machineBoxesByMachineUId[uid]

    machineBox = new SidebarMachineBox {}, machineAndWorkspaceData
    @addSubView machineBox
    @machineBoxes.push machineBox
    @machineBoxesByMachineUId[uid] = machineBox

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
      { machine } = box
      if machine.uid is machineUId
        # don't select not approved machines
        if not machine.isMine() and machine.isPermanent() and not machine.isApproved()
          return no

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


  getMachines: ->

    machines = []

    @forEachMachineBoxes (box) -> machines.push box.machine

    return machines
