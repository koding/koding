class IntroView extends JView

  constructor:(options={}, data)->
    options.cssClass = 'intro-view'
    super options, data

  destroyIntro:->
    @setClass 'out'
    @utils.wait '500', => @destroy()

  viewAppended:->

    @addSubView @slider = new KDSlideShowView
      animation : 'rotate'

    @slider.addPage page1 = new KDSlidePageView

    page1.addSubView new KDCustomHTMLView
      partial   : "A new way for developers to work"
      cssClass  : "slogan"

    page1.addSubView new KDCustomHTMLView
      partial   : "Software development has finally evolved,<br> It's now social, in the browser and free!"
      cssClass  : "sub-slogan"

    @slider.addPage page2 = new KDSlidePageView
      content  : 'Page 2'

    @slider.addSubPage page10 = new KDSlidePageView
      content  : 'Subpage #1 of Page 2'

    @slider.addSubPage page11 = new KDSlidePageView
      content  : 'Subpage #2 of Page 2'

    @slider.addSubPage page12 = new KDSlidePageView
      content  : 'Subpage #3 of Page 2'

    @slider.addPage page3 = new KDSlidePageView
      content  : 'Page 3'

    @slider.addSubPage page13 = new KDSlidePageView
      content  : 'Subpage #1 of Page 3'

    buttons = new KDCustomHTMLView cssClass : 'buttons'
    buttons.addSubView emailSignupButton  = new KDButtonView
      cssClass  : "email"
      partial   : "<i></i>Sign up <span>with email</span>"
      callback  : -> KD.getSingleton('router').handleRoute '/Register'

    buttons.addSubView gitHubSignupButton = new KDButtonView
      cssClass  : "github"
      partial   : "<i></i>Sign up <span>with gitHub</span>"
      callback  : -> KD.getSingleton("oauthController").openPopup "github"

    @addSubView buttons

    @addSubView nextButton = new KDButtonView
      cssClass : 'next'
      title    : 'Next Page'
      callback : => @slider.nextPage()

    nextButton.setStyle
      position : 'absolute'
      right    : '10px'
      bottom   : '10px'
      zIndex   : 5

    @addSubView prevButton = new KDButtonView
      cssClass : 'prev'
      title    : 'Previous Page'
      callback : => @slider.previousPage()

    prevButton.setStyle
      position : 'absolute'
      left     : '10px'
      bottom   : '10px'
      zIndex   : 5

    @addSubView previousSubPageButton = new KDButtonView
      cssClass : 'Down'
      title    : 'Previous SubPage'
      callback : => @slider.previousSubPage()

    previousSubPageButton.setStyle
      position : 'absolute'
      left     : '200px'
      bottom   : '10px'
      zIndex   : 5

    @addSubView nextSubPageButton = new KDButtonView
      cssClass : 'up'
      title    : 'Next SubPage'
      callback : => @slider.nextSubPage()

    nextSubPageButton.setStyle
      position : 'absolute'
      right    : '200px'
      bottom   : '10px'
      zIndex   : 5

KD.introView = new IntroView
KD.introView.appendToDomBody()