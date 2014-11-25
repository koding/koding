class WelcomeModal extends KDModalView

  constructor: (options = {}, data) ->

    options.cssClass      = 'welcome-modal'
    options.overlay       = yes
    options.overlayClick  = no
    options.width         = 766
    options.height        = 519

    super options, data

    @addSubView new KDCustomHTMLView
      cssClass    : 'decoration-image'
      tagName     : 'figure'

    @addSubView content = new KDCustomHTMLView
      cssClass    : 'content'

    content.addSubView new KDHeaderView
      type        : 'big'
      title       : 'Welcome Home'

    content.addSubView new KDHeaderView
      type        : 'medium'
      title       : 'An all new Koding, all ready to go!'

    content.addSubView new KDCustomHTMLView
      tagName     : 'p'
      partial     : "
        Robust VMs, a new IDE/Terminal and awesome new social
        features... all that is just a click away. You are about to
        experience a whole new Koding and you will fall in love all
        over again.
      "

    content.addSubView new CustomLinkView
      cssClass    : 'welcome-btn'
      title       : 'Read our blog post about this release'
      click       : =>
        window.open 'http://blog.koding.com/2014/09/new-release', '_blank'
        @destroy()

    content.addSubView new CustomLinkView
      cssClass    : 'welcome-btn'
      title       : 'Explore the new koding now'
      click       : @bound 'cancel'

