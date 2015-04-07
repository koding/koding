HomeRegisterForm = require './registerform'
FooterView       = require './footerview'
CustomLinkView   = require './../core/customlinkview'

module.exports = class HomeView extends KDView

  COLORS    = [ 'orange', 'gray', 'blue', 'green', 'dark-blue' ]
  IMAGEPATH = '/a/site.landing/images/slideshow'
  IMAGES    = [
    [ 'ss-ide.png',           '1 Billion+ lines of code written.' ]
    [ 'ss-terminal.png',      '500,000+ strong global dev community.' ]
    [ 'ss-channels.png',      '18,000,000+ VMs spun up and counting.' ]
    [ 'ss-settings.png',      '5+ Petabytes of VM space allocated.' ]
    [ 'ss-chats.png',         '5,000+ developers write code here every day.' ]
  ]
  ORDER     = [ 'prev', 'current', 'next']
  INDEX     = 0
  INFODOTS  = [
    #IDE
    [
      {
        position : [10, 15] #percent
        content  : 'Your VM is easily accesible at all times. \n Create a workspace for every project that you are working on.'
      },
      {
        position : [55, 6] #percent
        content  : 'The IDE supports multi-tab layouts so that you \n can have all your files open and within easy reach.'
      },
      {
        position : [55, 32] #percent
        content  : 'The Koding IDE supports syntax highlighting for \n all major programming languages.'
      },
      {
        position : [26, 42] #percent
        content  : 'Filetree gives you easy access to your VMs file system \n and supports easy uploads using drag and drop.'
      }
    ]
    #Terminal
    [
      {
        position : [55, 6] #percent
        content  : 'Terminal and IDE tabs can be opened vertically or \n horizontally. You can even split them!'
      },
      {
        position : [54, 51] #percent
        content  : 'You can open as many Terminal tabs as you want \n and keep an eye on all those scripts.'
      },
      {
        position : [65, 65] #percent
        content  : 'The Koding Terminal supports many themes. \n We\'ve designed it to be beautiful and responsive.'
      },
      {
        position : [10, 17] #percent
        content  : 'Each new workspace gets its own set of IDE and Terminal tabs \n so you can easily manage different projects.'
      }
    ]
    #Channels
    [
      {
        position : [31, 11] #percent
        content  : 'Share news, links, ideas etc. with a community \n of like minded developers from around the world.'
      },
      {
        position : [8, 28] #percent
        content  : 'Follow a variety of topics that are of interest to you \n and keep up with the latest conversation.'
      },
      {
        position : [88, 38] #percent
        content  : 'Easily see which top topics are of interest to \n the Koding Community.'
      },
      {
        position : [9, 44] #percent
        content  : 'If a topic of discussion is for your team only, \n then easily take it to a private message.'
      }
    ]
    #Settings
    [
      {
        position : [10, 17] #percent
        content  : 'Koding VMs run Ubuntu 14.04 and come pre-installed with \n most of the latest developer oriented software.'
      },
      {
        position : [40, 24] #percent
        content  : 'All Koding VMs come with public IPs. \n Very useful when using FTP, SSH, etc.'
      },
      {
        position : [42, 41] #percent
        content  : 'Easy links to helpful guides that show you how \n you can connect to your VM using SSH, FTP and much more!'
      },
      {
        position : [37, 53] #percent
        content  : 'If you prefer, you can keep your VM running all the time by upgrading.'
      },
      {
        position : [20, 58] #percent
        content  : 'You can create custom sub-domains for your VM so you can \n easily run multiple virtual servers.'
      }
    ]
    #Chats
    [
      {
        position : [15, 38] #percent
        content  : 'Get notified when there is new information \n for you to view.'
      },
      {
        position : [42, 6] #percent
        content  : 'Add as many private chat participants as you want!'
      },
      {
        position : [64, 6] #percent
        content  : 'Easily leave any chat.'
      },
      {
        position : [66, 40] #percent
        content  : 'Messages posted on Koding\'s private or public \n channels have markdown support.'
      }
    ]
  ]

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
