class FeederOnboardingView extends JView

  constructor:(options = {}, data)->

    options.cssClass  = "onboarding-wrapper hidden"
    p                 = options.pistachio
    @pistachio        = -> "#{p}{{> @close}}"
    options.pistachio =  null

    super options, data

    @close = new CustomLinkView
      title      : ''
      icon       :
        cssClass : "close-icon"
      click      : (event)=>
        event.preventDefault()
        appManager = @getSingleton("appManager")
        app        = appManager.getFrontApp()
        app.appStorage?.fetchStorage =>
          {name} = @getOptions()
          app.appStorage.setValue "onboardingMessageIsReadFor#{name.capitalize()}Tab", yes
          @emit "OnboardingMessageCloseIconClicked"
