kd                        = require 'kd'
KDModalView               = kd.ModalView
KDButtonView              = kd.ButtonView
KDCustomHTMLView          = kd.CustomHTMLView

checkFlag                 = require 'app/util/checkFlag'
{handleNewMachineRequest} = require 'app/providers/computehelpers'

ModalMachineItem          = require './modalmachineitem'


module.exports = class MoreVMsModal extends KDModalView

  constructor: (options = {}, data = []) ->

    options.cssClass = kd.utils.curry 'more-modal more-vms', options.cssClass
    options.width    = 462
    options.title    = 'Your VMs'
    options.overlay  = yes

    super options, data

    @createStackStatusMessage()
    @createAddKodingVMButton()
    @createAddYourVMButton()
    @listMachines()


  createStackStatusMessage: ->

    {stackStatus} = @getOptions()
    return  if not stackStatus or stackStatus.code is 0

    @addSubView new KDCustomHTMLView
      cssClass : 'changed-stack'
      partial  : "Current stack template is changed,
                  you need to reinitialize current
                  stack to get latest changes."


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
