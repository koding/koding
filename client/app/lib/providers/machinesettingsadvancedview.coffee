kd               = require 'kd'
KDView           = kd.View
KDButtonView     = kd.ButtonView
KDCustomHTMLView = kd.CustomHTMLView


module.exports = class MachineSettingsAdvancedView extends KDView

  constructor: (options = {}, data) ->

    super options, data

    @machine = data

    @createButton 'Reinitialize your VM', 'reinit', 'Reset your VM back to its original state'
    @createButton 'Terminate your VM', 'terminate', 'Completely remove your VM'


  createButton: (title, className, desc) ->

    @addSubView new KDCustomHTMLView
      cssClass : "big-icon advanced #{className}"
      click    : (e) => @handleClick e, className
      partial  : """
        <figure>
          <span class="icon"></span>
        </figure>
        <div class="label">
          <p>#{title}</p>
          <span>#{desc}</span>
        </div>
      """

  handleClick: (e, buttonType) ->

    { tagName }           = e.target
    parentTagName         = e.target.parentNode.tagName
    { computeController } = kd.singletons

    if tagName is 'FIGURE' or parentTagName is 'FIGURE' or tagName is 'P'

      switch buttonType
        when 'reinit'    then computeController.reinit  @machine
        when 'terminate' then computeController.destroy @machine

      @emit 'ModalDestroyRequested'
