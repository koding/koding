class FeederOnboardingView extends JView

  constructor:(options = {}, data)->

    options.cssClass    = "onboarding-wrapper"
    options.pistachio  +=  "{{> @close}}"

    @close = new CustomLinkView
      icon       :
        cssClass : "close-icon"


