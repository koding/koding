class FeederOnboardingView extends KDCustomHTMLView

  constructor:(options = {}, data)->

    options.cssClass  = "onboarding-wrapper"
    super options, data
    @addCloseButton()


  addCloseButton:->

    @addSubView @close = new CustomLinkView
      title      : ''
      cssClass   : 'onboarding-close'
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
