kd = require 'kd'
WizardSteps = require './wizardsteps'

module.exports = class WizardProgressPane extends kd.View

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'wizard-progress-pane', options.cssClass
    super options, data

    @addSteps()


  addSteps: ->

    { currentStep }      = @getOptions()
    isCurrentStepReached = no
    index                = 0

    for key, value of WizardSteps
      isCurrentStep        = value is currentStep
      isCurrentStepReached = yes  if isCurrentStep

      cssClass = 'wizard-step'
      if not isCurrentStepReached
        cssClass += ' completed'
      else if isCurrentStep
        cssClass += ' current'

      @addSubView new kd.CustomHTMLView {
        cssClass
        partial  : """
          <div class='alien'></div>
          <span class='index'>
            <span class='indexText'>#{++index}</span>
            <span class='indexSign'></span>
          </span>
          #{value}
        """
      }
