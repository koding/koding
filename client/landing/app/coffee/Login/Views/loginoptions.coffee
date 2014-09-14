class LoginOptions extends KDView
  viewAppended:->

    inFrame = KD.runningInFrame()

    @addSubView new KDHeaderView
      type      : "small"
      title     : "SIGN IN WITH:"

    @addSubView optionsHolder = new KDCustomHTMLView
      tagName   : "ul"
      cssClass  : "login-options"

    optionsHolder.addSubView new KDCustomHTMLView
      tagName   : "li"
      cssClass  : "koding active"
      partial   : "koding"
      tooltip   :
        title   : "<p class='login-tip'>Sign in with Koding</p>"

    optionsHolder.addSubView new KDCustomHTMLView
      tagName   : "li"
      cssClass  : "github #{if inFrame then 'hidden' else ''}"
      partial   : "github"
      click     : ->
        return new KDNotificationView title: "Login restricted"
        #KD.singletons.oauthController.openPopup "github"
      tooltip   :
        title   : "<p class='login-tip'>Sign in with GitHub</p>"
