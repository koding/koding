kd = require 'kd'
IDEOnboardingModalContent = require './ideonboardingmodalcontent'
EnvironmentsModalView = require 'app/providers/environmentsmodalview'


module.exports = class IDEOnboardingModal extends EnvironmentsModalView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'ide-onboarding-modal', options.cssClass
    options.width    = 590
    options.height   = 430

    super options, data

    @content = new IDEOnboardingModalContent
    @content.on 'GetStartedButtonClicked', @bound 'handleGetStarted'

    @addSubView @content

    @show()


  handleGetStarted: ->

    { appStorageController } = kd.singletons

    appStorage = appStorageController.storage 'IDE', '1.0.0'
    appStorage.setValue 'hideOnboardingModal', yes

    @destroy()

    @emit 'OnboardingModalDismissed'
