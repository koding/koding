class RegisterOptions extends KDView
  viewAppended:->
    @addSubView new KDHeaderView
      type     : "small"
      title    : "REGISTER WITH:"
    
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
      cssClass : "github"
      partial  : "github"
      tooltip  :
        title  : "<p class='login-tip'>Register with GitHub <cite>coming soon...</cite></p>"

    optionsHolder.addSubView new KDCustomHTMLView
      tagName  : "li"
      cssClass : "facebook"
      partial  : "facebook"
      tooltip  :
        title  : "<p class='login-tip'>Register with Facebook <cite>coming soon...</cite></p>"

    optionsHolder.addSubView new KDCustomHTMLView
      tagName  : "li"
      cssClass : "google"
      partial  : "google"
      tooltip  :
        title  : "<p class='login-tip'>Register with Google <cite>coming soon...</cite></p>"
