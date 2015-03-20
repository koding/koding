kd = require 'kd'
KDButtonView = kd.ButtonView
SidebarSearchModal = require './sidebarsearchmodal'
ModalMachineItem = require './modalmachineitem'
{handleNewMachineRequest} = require '../../providers/computehelpers'
checkFlag = require 'app/util/checkFlag'

module.exports = class MoreVMsModal extends SidebarSearchModal

  constructor: (options = {}, data = []) ->

    hasContainer             = options.container?

    options.cssClass         = kd.utils.curry 'more-modal more-vms', options.cssClass
    options.width            = 462
    options.title          or= 'Your VMs'
    options.disableSearch    = yes
    options.itemClass      or= ModalMachineItem
    options.bindModalDestroy = no
    options.appendToDomBody  = !hasContainer
    options.draggable        = no
    options.overlay          = !hasContainer

    super options, data

    if container = @getOption 'container'
      kd.utils.defer => container.addSubView this

  viewAppended: ->

    @addButton = new KDButtonView
      title    : "Create a Koding VM"
      style    : 'add-big-btn create-koding-vm'
      icon     : yes
      loader   : color : '#333'
      callback : =>
        @addButton.showLoader()
        handleNewMachineRequest provider: 'koding', @bound 'destroy'

    @addSubView @addButton, '.kdmodal-content'

    if checkFlag 'super-admin'
      
      @setClass 'managed'
      @addManagedButton = new KDButtonView
        title    : "Add Your own VM"
        style    : 'add-big-btn'
        icon     : yes
        loader   : color : '#333'
        callback : =>
          @addManagedButton.showLoader()
          handleNewMachineRequest provider: 'managed', @bound 'destroy'

      @addSubView @addManagedButton, '.kdmodal-content'

    super


  populate: ->

    machines = @getData()

    for machine in machines
      item = @listController.addItem machine.data
      item.once 'ModalItemSelected', @bound 'destroy'
