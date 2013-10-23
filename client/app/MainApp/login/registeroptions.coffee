class RegisterOptions extends KDView
  viewAppended:->

    inFrame = KD.runningInFrame()

    @addSubView optionsHolder = new KDCustomHTMLView
      tagName  : "ul"
      cssClass : "login-options"

    optionsHolder.addSubView new KDCustomHTMLView
      tagName  : "li"
      cssClass : "koding active"
      partial  : "koding"
      tooltip  :
        title  : "<p class='login-tip'>Register with Koding</p>"

    optionsHolder.addSubView new KDCustomHTMLView
      tagName  : "li"
      cssClass : "github active #{'hidden' if inFrame}"
      partial  : "github"
      click    : -> KD.singletons.oauthController.openPopup "github"
      tooltip  :
        title  : "<p class='login-tip'>Register with GitHub</p>"
