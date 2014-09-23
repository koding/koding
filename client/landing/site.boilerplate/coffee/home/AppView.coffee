HomeRegisterForm = require './registerform'
FooterView       = require './footerview'

module.exports = class HomeView extends KDView

  COLORS    = [ 'gray', 'blue', 'orange', 'red', 'green', 'dark-blue' ]
  IMAGEPATH = '/a/out/images/slideshow'
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

    @slideShow = new KDView

    @footer = new FooterView

    @setPartial @partial()

    @addSubView @signUpForm, '.introduction article'
    @addSubView @slideShow
    @addSubView @footer

    INDEX = KD.utils.getRandomNumber COLORS.length - 1
    @changeColor()

    @once 'viewAppended', ->
      @setClass 'anim'
      KD.utils.repeat 60e3, @bound 'nextColor'

  click: -> @nextColor()

  nextColor: -> @changeColor INDEX = (INDEX + 1) % 6


  changeColor: ->

    @unsetClass color for color in COLORS
    @setClass COLORS[INDEX]


  getImgElements = ->  ("<figure class='#{ORDINALS[i]}'><div src='#{IMAGEPATH}/#{IMAGES[i]}' ></div></figure>" for image, i in IMAGES).join ''


  partial: ->

    slogan = if KD.siteName
    then "Welcome to #{KD.siteName}"
    else "Full Stack Browser Based Development"

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

    <section class="screenshots">
      <div>
        #{getImgElements()}
      </div>
    </section>

    <section class="used-at">
      <div>
        <h3>Loved by developers at</h3>
        <figure></figure>
      </div>
    </section>

    """


