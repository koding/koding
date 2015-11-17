kd                    = require 'kd'
KDView                = kd.View
KDCustomHTMLView      = kd.CustomHTMLView
FindManagedNodesModal = require './managed/findnodesmodal'


module.exports = class MachineSettingsAdvancedView extends KDView

  constructor: (options = {}, data) ->

    super options, data

    @machine = data

    reinitButton   = @createButton 'reinit', 'Reinitialize your VM', 'reinit', 'This will take your VM back to its original state. (Note: you will lose all your data)'
    terminateClass = 'terminate'
    terminateTitle = 'Terminate your VM'
    terminateText  = 'This will delete your VM completely. (Note: you will lose all your data)'

    if @machine.isManaged()
      reinitButton.hide()
      terminateClass = 'terminate terminate-managed'
      terminateTitle = 'Disconnect your VM'
      terminateText  = 'Remove the connection between your Machine and Koding.'

    terminateButton = @createButton 'terminate', terminateTitle, terminateClass, terminateText


  createButton: (callbackName, title, className, desc) ->

    @addSubView new KDCustomHTMLView
      cssClass : "big-icon advanced #{className}"
      click    : (e) => @handleButtonClick e, callbackName
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
        when 'terminate' then computeController.destroy @machine
        when 'reassign'  then new FindManagedNodesModal reassign: yes, @machine
        when 'reinit'
          if @machine.provider is 'aws'
            return new kd.NotificationView title: 'Coming soon', duration: 4500

          computeController.reinit  @machine

      @emit 'ModalDestroyRequested'
