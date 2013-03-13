class LoginOptions extends KDView
  viewAppended:->
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
      cssClass  : "github"
      partial   : "github"
      tooltip   :
        title   : "<p class='login-tip'>Sign in with GitHub <cite>coming soon...</cite></p>"

    optionsHolder.addSubView new KDCustomHTMLView
      tagName   : "li"
      cssClass  : "facebook"
      partial   : "facebook"
      tooltip   :
        title   : "<p class='login-tip'>Sign in with Facebook <cite>coming soon...</cite></p>"

    optionsHolder.addSubView new KDCustomHTMLView
      tagName   : "li"
      cssClass  : "google"
      partial   : "google"
      tooltip   :
        title   : "<p class='login-tip'>Sign in with Google <cite>coming soon...</cite></p>"
