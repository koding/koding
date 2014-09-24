HomeRegisterForm = require './registerform'
FooterView       = require './footerview'

module.exports = class HomeView extends KDView

  COLORS    = [ 'gray', 'blue', 'orange', 'red', 'green', 'dark-blue' ]
  IMAGEPATH = '/a/site.landing/images/slideshow'
  IMAGES    = [ 'ss-activity.jpg', 'ss-terminal.jpg', 'ss-teamwork.jpg' ]
  ORDINALS  = ['first', 'second', 'third']
  INDEX     = 0

  constructor: (options = {}, data)->

    super

    {router} = KD.singletons

    @signUpForm = new HomeRegisterForm
      cssClass    : 'login-form register no-anim'
      buttonTitle : 'Sign up'
      callback    : (formData) =>
        router.requireApp 'Login', (controller) =>
          controller.getView().showPasswordModal formData, @signUpForm

    @signUpForm.button.unsetClass 'green'
    @signUpForm.button.setClass 'yellow'

    @slideShow = new KDSlideShow
      direction    : 'leftToRight'
      touchEnabled : no

    @footer = new FooterView

    @setPartial @partial()

    @addSubView @signUpForm, '.introduction article'
    @addSubView @slideShow, '.screenshots'
    @addSubView @footer

    for image, i in IMAGES
      @slideShow.addSubView new KDSlidePageView
        tagName  : 'figure'
        cssClass : ORDINALS[i]
        partial  : "<img src='#{IMAGEPATH}/#{IMAGES[i]}' />"

    INDEX = KD.utils.getRandomNumber COLORS.length - 1
    @changeColor()

    @once 'viewAppended', ->
      @setClass 'anim'
      KD.utils.repeat 3e5, @bound 'nextColor'

  click: -> @nextColor()

  nextColor: -> @changeColor INDEX = (INDEX + 1) % 6


  changeColor: ->

    @unsetClass color for color in COLORS
    @setClass COLORS[INDEX]


  partial: ->

    """
    <section class="introduction">
      <div>
        <article>
          <h1>Full Stack Browser Based Development</h2>
          <h2>
            Build Node, Go, Django, Rails, PHP and other apps and never install a dev environment on your laptop again.
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


