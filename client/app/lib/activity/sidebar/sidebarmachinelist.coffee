kd                = require 'kd'
KDCustomHTMLView  = kd.CustomHTMLView

EnvironmentsModal = require 'app/environment/environmentsmodal'

CustomLinkView    = require 'app/customlinkview'
SidebarMachineBox = require 'app/activity/sidebar/sidebarmachinebox'


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
      click    : @bound 'headerClickHandler'

    if hasPlusIcon
      @header.addSubView new CustomLinkView
        cssClass : 'add-icon buy-vm'
        title    : ' '

    @addSubView @header


  headerClickHandler: -> new EnvironmentsModal selected: @getOption 'stack'


  addMachineBoxes: (boxes) ->

    data = boxes or @getData()
    data.forEach @bound 'addMachineBox'


  addMachineBox: (machineAndWorkspaceData) ->

    { uid } = machineAndWorkspaceData.machine

    return no  if @machineBoxesByMachineUId[uid]

    box = new SidebarMachineBox {}, machineAndWorkspaceData

    box.once 'KDObjectWillBeDestroyed', @lazyBound 'handleMachineBoxDestroy', box

    @forwardEvent box, 'ListStateChanged'

    @addSubView box
    @machineBoxes.push box
    @machineBoxesByMachineUId[uid] = box


  handleMachineBoxDestroy: (box) ->

    @machineBoxes.splice @machineBoxes.indexOf(box), 1
    delete @machineBoxesByMachineUId[box.machine.uid]
    @emit 'MachineBoxDestroyed', box


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
        if not machine.isMine() and not machine.isApproved()
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


  updateVisibility: ->

    shownBoxes = @machineBoxes.filter (box) -> not box.hasClass 'hidden'

    if shownBoxes.length is 0
    then @hide()
    else @show()
