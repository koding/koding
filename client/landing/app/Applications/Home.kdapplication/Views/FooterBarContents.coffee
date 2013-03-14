class MainPageFooterView extends KDView
  viewAppended:->
    @addLeftLinks()
    @addRightLinks()

  addLeftLinks:->
    @addSubView @linkHolder = new KDView
      cssClass  : "footer-left"

    @linkHolder.addSubView new KDView
      tagName     : 'a'
      cssClass    : 'footer-fb-link'
      partial     : 'Facebook'
      attributes  :
        href        : 'https://www.facebook.com/pages/Koding/109012155844171'
        target      : '_blank'

    @linkHolder.addSubView new KDView
      tagName     : 'a'
      cssClass    : 'footer-tw-link'
      partial     : 'Twitter'
      attributes  :
        href        : 'https://twitter.com/kodingen'
        target      : '_blank'

  addRightLinks:->
    @addSubView @buttonHolder = new KDView
      cssClass  : "footer-right"

    mainController = @getSingleton('mainController')

    if not @getData().about
      @buttonHolder.addSubView new KDView
        tagName     : 'a'
        partial     : "About Koding"
        attributes  :
          href        : '#'
        click     : =>
          @getDelegate().emit "AboutButtonClicked"

    @buttonHolder.addSubView new KDView
      tagName     : 'a'
      partial     : "Sign In"
      attributes  :
        href        : '#'
      click     : =>
        mainController.loginScreen.showView =>
          mainController.loginScreen.animateToForm "login"

    @buttonHolder.addSubView new KDView
      tagName     : 'a'
      partial     : "Create an Account"
      attributes  :
        href        : '#'
      click     : =>
        mainController.loginScreen.showView =>
          mainController.loginScreen.animateToForm "register"

