HomeRegisterForm = require './registerform'
FooterView       = require './footerview'
CustomLinkView   = require './../core/customlinkview'

module.exports = class HomeView extends KDView

  COLORS    = [ 'gray', 'blue', 'green', 'dark-blue' ]
  IMAGEPATH = '/a/site.landing/images/slideshow'
  IMAGES    = [ 'ss-terminal.png', 'ss-activity.png', 'ss-ide.png', 'ss-ide-collapsed.png', 'ss-chat.png' ]
  ORDER     = [ 'prev', 'current', 'next']
  INDEX     = 0

  constructor: (options = {}, data)->

    super

    {router} = KD.singletons

    @signUpForm = new HomeRegisterForm
      cssClass    : 'login-form register no-anim'
      buttonTitle : 'SIGN UP'
      callback    : (formData) =>
        router.requireApp 'Login', (controller) =>
          controller.getView().showPasswordModal formData, @signUpForm

    @signUpForm.button.unsetClass 'green'
    @signUpForm.button.setClass 'yellow'

    @slideShow    = new KDView
    @slideShowNav = new KDView
      tagName     : 'nav'
      cssClass    : 'slideshow-nav'

    @footer = new FooterView

    @setPartial @partial()

    @addSubView @signUpForm, '.introduction article'
    @addSubView @slideShow, '.screenshots'
    @addSubView @footer

    @nextButton = new CustomLinkView
      title    : ''
      cssClass : 'ss-button next'
      icon     : {}
      click    : => @rotateImagesBy 1

    @prevButton = new CustomLinkView
      title    : ''
      cssClass : 'ss-button prev'
      icon     : {}
      click    : => @rotateImagesBy -1

    @addSubView @nextButton, '.screenshots'
    @addSubView @prevButton, '.screenshots'

    @addSubView @slideShowNav, '.used-at'

    view = this
    @imageSets = for image, i in IMAGES
      @slideShow.addSubView slide = new KDCustomHTMLView
        tagName  : 'figure'
        cssClass : ORDER[i]
        partial  : "<img src='#{IMAGEPATH}/#{IMAGES[i]}' />"
        click    : ->
          for [_slide, _dot], _i in view.imageSets when _slide is this
            view.rotateImagesBy _i - 1

      @slideShowNav.addSubView dot = new CustomLinkView
        title    : "Screenshot ##{i}"
        delegate : slide
        img      : IMAGES[i]
        cssClass : "nav-dot#{if i is 1 then ' active' else ''}"
        click    : -> @getDelegate().emit 'click'

      [slide, dot]

    INDEX = KD.utils.getRandomNumber(COLORS.length - 1)
    @changeColor()

    @once 'viewAppended', ->
      @setClass 'anim'
      @$('section.introduction').addClass 'shine'
      KD.utils.repeat 3e5, @bound 'nextColor'


  rotateImagesBy: (n) ->

    {length} = @imageSets
    n += length while length and n < 0
    @imageSets.push.apply @imageSets, @imageSets.splice 0, n

    allClasses = ORDER.join ' '

    for [image, dot], i in @imageSets
      image.unsetClass allClasses
      dot.unsetClass 'active'
      image.setClass ORDER[i]
      if ORDER[i] is 'current'
        dot.setClass 'active'


  nextColor: -> @changeColor INDEX = (INDEX + 1) % COLORS.length


  changeColor: ->

    @unsetClass color for color in COLORS
    @setClass COLORS[INDEX]


  partial: ->

    """
    <section class="introduction">
      <div>
        <article>
          <h1>Your next localhost is here.</h1>
          <h2>
            Develop in Go, Python, Node, Ruby, PHP, etc or play with Docker, Wordpress, Django, Laravel or create Android, IOS/iPhone, HTML5 apps. All for FREE!
          </h2>
        </article>
      </div>
    </section>

    <section class="screenshots"></section>

    <section class="used-at">
      <div>
        <h3>Loved by developers at</h3>
        <figure></figure>
      </div>
    </section>

    """


