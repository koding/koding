kd                    = require 'kd'
KDView                = kd.View
KDButtonView          = kd.ButtonView
KDCustomHTMLView      = kd.CustomHTMLView
FindManagedNodesModal = require './managed/findnodesmodal'


module.exports = class MachineSettingsAdvancedView extends KDView

  constructor: (options = {}, data) ->

    super options, data

    @machine = data

    reinitButton   = @createButton 'Reinitialize your VM', 'reinit', 'Reset your VM back to its original state'
    reassignButton = @createButton 'Reassign your VM', 'reassign', 'Reassign your VM to another node'
    terminateTitle = 'Terminate your VM'

    if @machine.isManaged()
      reinitButton.hide()
      reassignButton.show()
      terminateTitle = 'Delete your VM'
    else
      reassignButton.hide()

    terminateButton = @createButton terminateTitle, 'terminate', 'Completely remove your VM'


  createButton: (title, className, desc) ->

    @addSubView new KDCustomHTMLView
      cssClass : "big-icon advanced #{className}"
      click    : (e) => @handleButtonClick e, className
      partial  : """
        <figure>
          <span class="icon"></span>
        </figure>
        <div class="label">
          <p>#{title}</p>
          <span>#{desc}</span>
        </div>
      """

  handleButtonClick: (e, buttonType) ->

    { tagName }           = e.target
    parentTagName         = e.target.parentNode.tagName
    { computeController } = kd.singletons

    if tagName is 'FIGURE' or parentTagName is 'FIGURE' or tagName is 'P'

      switch buttonType
        when 'reinit'    then computeController.reinit  @machine
        when 'terminate' then computeController.destroy @machine
        when 'reassign'  then new FindManagedNodesModal reassign: yes, @machine

      @emit 'ModalDestroyRequested'
