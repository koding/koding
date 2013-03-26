class FeederOnboardingView extends KDCustomHTMLView

  constructor:(options = {}, data)->

    options.cssClass  = "onboarding-wrapper hidden"
    p                 = options.pistachio
    @pistachio        = -> "{{> @close}}#{p}"
    options.pistachio =  null

    super options, data

    @close = new CustomLinkView
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

  viewAppended: JView::viewAppended