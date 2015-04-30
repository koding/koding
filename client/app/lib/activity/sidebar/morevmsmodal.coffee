kd                        = require 'kd'
checkFlag                 = require 'app/util/checkFlag'
KDModalView               = kd.ModalView
KDButtonView              = kd.ButtonView
ModalMachineItem          = require './modalmachineitem'
{handleNewMachineRequest} = require '../../providers/computehelpers'


module.exports = class MoreVMsModal extends KDModalView

  constructor: (options = {}, data = []) ->

    options.cssClass = kd.utils.curry 'more-modal more-vms', options.cssClass
    options.width    = 462
    options.title    = 'Your VMs'
    options.overlay  = yes

    super options, data

    @createAddKodingVMButton()
    @createAddYourVMButton()
    @listMachines()


  createAddKodingVMButton: ->

    @addButton = new KDButtonView
      title    : "Create a Koding VM"
      style    : 'add-big-btn create-koding-vm'
      icon     : yes
      loader   : color : '#333'
      callback : =>
        @addButton.showLoader()
        handleNewMachineRequest provider: 'koding', @bound 'destroy'

    @addSubView @addButton, '.kdmodal-content'


  createAddYourVMButton: ->

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


  listMachines: ->

    for machine in @getData()
      @addSubView view = new ModalMachineItem {}, machine.data
      view.once 'ModalItemSelected', @bound 'destroy'
