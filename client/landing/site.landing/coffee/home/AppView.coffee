HomeRegisterForm = require './registerform'
FooterView       = require './footerview'
CustomLinkView   = require './../core/customlinkview'
MainHeaderView   = require './../core/mainheaderview'

module.exports = class HomeView extends KDView

  IMAGES    = require './images'
  INFODOTS  = require './infodots'
  IMAGEPATH = '/a/site.landing/images/slideshow'
  COLORS    = [ 'orange', 'gray', 'blue', 'green', 'dark-blue' ]
  ORDER     = [ 'prev', 'current', 'next']
  INDEX     = 0

  constructor: (options = {}, data)->

    super

    {router}  = KD.singletons

    @infoDots = []

    @signUpForm = new HomeRegisterForm
      cssClass    : 'login-form register no-anim'
      buttonTitle : 'SIGN UP'
      callback    : (formData) =>
        router.requireApp 'Login', (controller) =>
          controller.getView().showExtraInformation formData, @signUpForm

    @signUpForm.button.unsetClass 'green'
    @signUpForm.button.setClass 'yellow'

    @slideShow    = new KDView
    @slideShowNav = new KDView
      tagName     : 'nav'
      cssClass    : 'slideshow-nav'

    @footer = new FooterView

    @nextButton = new CustomLinkView
      title    : ''
      cssClass : 'ss-button next'
      icon     : {}
      click    : =>
        @rotateImagesBy 1

        KD.utils.trackEvent "Homepage slider, click",
          category : 'userInteraction'
          action   : 'clicks'
          label    : 'homeSliderRight'

    @prevButton = new CustomLinkView
      title    : ''
      cssClass : 'ss-button prev'
      icon     : {}
      click    : =>
        @rotateImagesBy -1

        KD.utils.trackEvent "Homepage slider, click",
          category : 'userInteraction'
          action   : 'clicks'
          label    : 'homeSliderLeft'

    view = this
    @imageSets = for [image, slogan], i in IMAGES

      imgUrl   = if window.devicePixelRatio > 1
      then "#{IMAGEPATH}/2x/#{image}"
      else "#{IMAGEPATH}/#{image}"

      @slideShow.addSubView slide = new KDCustomHTMLView
        tagName  : 'figure'
        cssClass : ORDER[i]
        slogan   : slogan
        partial  : "<img src='#{imgUrl}' />"
        click    : ->
          for [_slide, _dot], _i in view.imageSets when _slide is this
            view.rotateImagesBy _i - 1

      @slideShowNav.addSubView dot = new CustomLinkView
        title    : "Screenshot ##{i}"
        delegate : slide
        img      : image
        cssClass : "nav-dot#{if i is 1 then ' active' else ''}"
        click    : ->
          @getDelegate().emit 'click'

          KD.utils.trackEvent "Homepage dots, click",
            category : 'userInteraction'
            action   : 'clicks'
            label    : 'homeSliderDots'

      infoDots = INFODOTS[i]

      if infoDots then for infoDot in infoDots
        {position, content} = infoDot

        slide.addSubView instance = new KDCustomHTMLView
          cssClass          : 'info-dot'
          attributes        :
            style           : "left: #{position[0]}%; top: #{position[1]}%;"
            'data-content'  : content

        @infoDots.push instance


      [slide, dot]

    INDEX = KD.utils.getRandomNumber(COLORS.length) - 1
    @changeColor()

    @once 'viewAppended', ->
      @setClass 'anim'
      @$('section.introduction').addClass 'shine'
      KD.utils.repeat 3e5, @bound 'nextColor'

    @on 'CurrentImageChanged', (current) =>
      # temp animation
      # needs a change to match w/ the slideshow animation
      {slogan} = current.getOptions()
      $h1 = $('.introduction h1').first()
      $h1.addClass 'flip'
      KD.utils.wait 200, ->
        $h1.text slogan
        $h1.removeClass 'flip'


    @addSubView new MainHeaderView
    @setPartial @partial()
    @addSubView @signUpForm, '.introduction article'
    @addSubView @slideShow, '.screenshots'
    @addSubView @footer
    @addSubView @nextButton, '.screenshots'
    @addSubView @prevButton, '.screenshots'
    @addSubView @slideShowNav, '.used-at'


  rotateImagesBy: (n) ->

    direction = if n > 0 then 'from-left' else 'from-right'

    {length} = @imageSets
    n += length while length and n < 0
    @imageSets.push.apply @imageSets, @imageSets.splice 0, n

    [nextCurrent] = @imageSets[1]

    allClasses  = ORDER.join ' '
    allClasses += ' from-left from-right'
    for [image, dot], i in @imageSets
      dot.unsetClass 'active'
      image.unsetClass allClasses

    for [image, dot], i in @imageSets when ORDER[i]
      image.setClass ORDER[i]
      if ORDER[i] is 'current'
        @emit 'CurrentImageChanged', image
        image.setClass direction
        dot.setClass 'active'


  nextColor: -> @changeColor INDEX = (INDEX + 1) % COLORS.length


  changeColor: ->

    @unsetClass color for color in COLORS
    @setClass COLORS[INDEX]

    changeInfoDotsColor = (color) =>

      introduction = @getElement().getElementsByClassName('introduction')[0]
      color        = window.getComputedStyle(introduction).backgroundColor

      for dot in @infoDots
        dot.getElement().style.backgroundColor = color

    if @viewIsReady
    then changeInfoDotsColor(color)
    else @once 'viewAppended', => changeInfoDotsColor(color)


  partial: ->
    """
    <section class="introduction">
      <div>
        <article>
          <h1>#{@imageSets[1][0].getOption 'slogan'}</h1>
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
