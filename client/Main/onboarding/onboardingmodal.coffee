class OnboardingModal extends KDBlockingModalView

  constructor: (options = {}, data) ->

    options.cssClass        = KD.utils.curry 'onboarding-modal', options.cssClass
    options.width           = 590
    # options.height          = 430
    options.overlay         = no
    options.appendToDomBody = no

    super options, data

    @content = new OnboardingModalContent
    @content.on 'GetStartedButtonClicked', @bound 'handleGetStarted'

    @addSubView @content

    @show()


  handleGetStarted: ->

    { appStorageController } = KD.singletons

    appStorage = appStorageController.storage 'Onboarding', '1.0'
    appStorage.setValue 'isOnboardingModalShown', yes

    @destroy()

    @emit 'OnboardingModalDismissed'


  show: ->

    {container} = @getOptions()
    @overlay    = new KDOverlayView
      appendToDomBody : no
      isRemovable     : no
      cssClass        : 'ide-modal-overlay'

    container.addSubView @overlay
    container.addSubView this


  destroy: ->

    @overlay.destroy()
    super


