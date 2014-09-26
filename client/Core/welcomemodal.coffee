class WelcomeModal extends KDModalView
  constructor : (options = {}) ->
    options.cssClass      = 'welcome-modal'
    options.overlay       = yes
    options.overlayClick  = no
    options.width         = 766
    options.height        = 519

    super options

    @createView()

  createView : ->
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
      title       : 'All new Koding, All ready to go!'

    content.addSubView new KDCustomHTMLView
      tagName     : 'p'
      partial     : "
        Somewhere out in space live The Herculoids! Zok, the laser-ray dragon!
        Igoo, the giant rock ape! Tundro, the tremendous! Gloop and Gleep,
        the formless, fearless wonders! With Zandor, their leader, and his
        wife, Tara, and son, Dorno, they team up to protect their planet from
        sinister invaders! All-strong! All-brave!
      "

    content.addSubView new CustomLinkView
      cssClass    : 'welcome-btn'
      title       : 'Let me explore the New Koding'
      click       : => @cancel()

    content.addSubView new CustomLinkView
      cssClass    : 'welcome-btn'
      title       : 'Learn more about the features'
      click       : ->
        KD.singletons['router'].handleRoute '/Features'

    content.addSubView new CustomLinkView
      cssClass    : 'welcome-btn'
      title       : 'Learn how to migrate your old VM'
      href        : 'http://learn.koding.com/migrate'




