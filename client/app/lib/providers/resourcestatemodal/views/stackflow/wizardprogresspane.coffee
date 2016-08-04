kd = require 'kd'
WizardSteps = require './wizardsteps'

module.exports = class WizardProgressPane extends kd.View

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'wizard-progress-pane', options.cssClass
    super options, data

    @addSteps()


  addSteps: ->

    index  = 0
    @steps = {}

    for step, data of WizardSteps
      title = data.title ? step
      @addSubView @steps[step] = new kd.CustomHTMLView {
        cssClass : 'wizard-step'
        partial  : """
          <div class='alien'></div>
          <span class='index'>
            <span class='indexText'>#{++index}</span>
            <span class='indexSign'></span>
          </span>
          #{title}
        """
      }


  setCurrentStep: (currentStep) ->

    isCurrentStepReached = no

    for key, view of @steps
      isCurrentStep        = key is currentStep
      isCurrentStepReached = yes  if isCurrentStep

      view.unsetClass 'completed'
      view.unsetClass 'current'
      if not isCurrentStepReached
        view.setClass 'completed'
      else if isCurrentStep
        view.setClass 'current'


  setWarningMode: (_on) ->

    if _on
      @setClass 'warning-mode'
    else
      @unsetClass 'warning-mode'
