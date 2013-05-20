class HomeSlideShow extends KDView

  slideData = [
      {
        bg      : "/images/bg/blurred/1.jpg"
        title   : "<p><span>A new way for</span><br><span>developers to work.</span></p>"
      },{
        bg      : "/images/bg/blurred/2.jpg"
        title   : "<p><span>Real software development</span><br><span>in the browser...</span></p>"
      },{
        bg      : "/images/bg/blurred/3.jpg"
        title   : "<p><span>with a great community </span><br><span>of developers...</span></p>"
      },{
        bg      : "/images/bg/blurred/4.jpg"
        title   : "<p><span>with a real VM and </span><br><span>a real Terminal...</span></p>"
      },{
        bg      : "/images/bg/blurred/5.jpg"
        title   : "<p><span>and free for everyone...</span></p>"
      },{
        bg      : "/images/bg/blurred/7.jpg"
        title   : """
          <figure class='video'>
            <iframe src="https://player.vimeo.com/video/45156018?color=ffb500" width="100%" height="100%" frameborder="0" webkitallowfullscreen="" mozallowfullscreen="" allowfullscreen=""></iframe>
          </figure>
        """
      }
    ]

  constructor:(options = {}, data)->

    data                  or= slideData
    options.tagName       or= "section"
    options.rotate         ?= yes
    options.rotationDelay or= 8000
    options.keydown         =
      left                  : => @interacted = yes; @slideTo "prev"
      right                 : => @interacted = yes; @slideTo "next"

    super options, data

    @slides     = []
    @pos        = 0
    @interacted = no
    @repeater   = null

  viewAppended:->

    @leftArrow = new KDCustomHTMLView
      domId    : "home-ss-left-arrow"
      tagName  : "a"
      cssClass : "arrow left"
      partial  : "<span></span>"
      click    : (event)=>
        @utils.stopDOMEvent event
        @slideTo "prev"
        @setKeyView()
        @interacted = yes

    @leftArrow.setX -40

    @rightArrow = new KDCustomHTMLView
      domId    : "home-ss-right-arrow"
      tagName  : "a"
      cssClass : "arrow right"
      partial  : "<span></span>"
      click    : (event)=>
        @utils.stopDOMEvent event
        @slideTo "next"
        @setKeyView()
        @interacted = yes

    @wrapper = new KDView
      cssClass   : 'clearfix'
      tagName    : 'ul'
      bind       : 'mousewheel'

    for slide, i in @getData()
      @wrapper.addSubView slide = new KDCustomHTMLView
        tagName    : 'li'
        partial    : slide.title
        cssClass   : "to-right" if i > 0
        attributes :
          style    : "background-image: url('#{slide.bg}'); width: #{100/@getData().length}%"
      @slides.push slide

    @setKeyView()
    @slideTo 0
    @$().html ""

    @addSubView @leftArrow
    @addSubView @rightArrow
    @wrapper.on "viewAppended", @bound "_windowDidResize"
    @getSingleton('mainView').on "transitionend", @bound "_windowDidResize"

    @on "FirstSlideShown", =>
      @rightArrow.$().css right : 0
      @leftArrow.$().css  left  : -40

    @on "LastSlideShown", =>
      @leftArrow.$().css  left  : 0
      @rightArrow.$().css right : -40

    @on "OtherSlideShown", =>
      @leftArrow.$().css  left  : ""
      @rightArrow.$().css right : ""

    @addSubView @wrapper

    if @getOption "rotate"
      @utils.wait 5000, =>
        if @pos is 0
          @repeater = @utils.repeat @getOption("rotationDelay"), =>
            unless @interacted
            then @rotate()
            else @utils.killRepeat @repeater

  click:-> @setKeyView()

  rotate:->

    if @pos is @slides.length - 1
    then @slideTo 0; @utils.killRepeat @repeater
    else @slideTo "next"

  slideTo:(index)->

    addend = switch index
      when "prev" then -1
      when "next" then 1
      else 0
    index  = null if addend isnt 0
    amount = @slides.length
    aWidth = 100 / amount
    pos    = index ? @pos
    pos    = pos + addend

    if pos < 0
    then pos = 0
    else if pos > amount-1
    then pos = amount - 1

    for slide, i in @slides when i isnt pos
      if pos < i
        slide.unsetClass 'to-left'
        slide.setClass 'to-right'
      else
        slide.setClass 'to-left'
        slide.unsetClass 'to-right'

    @pos = pos
    @slides[pos].unsetClass 'to-left to-right'
    @wrapper.$().css marginLeft : "-#{pos * 100}%"

    if pos is 0
    then @emit "FirstSlideShown"
    else if pos is amount-1
    then @emit "LastSlideShown"
    else @emit "OtherSlideShown"


  # pistachio:->
  #   """
  #   <ul class="clearfix">
  #   </ul>
  #   """

  #   """
  #   <ul class="clearfix">
  #     <li>
  #       <figure>
  #         <p class="flex-caption">A new way for developers to work.<span>We said.</span></p>
  #       </figure>
  #     </li>
  #     <li>
  #       <figure class='video'>
  #         <iframe src="https://player.vimeo.com/video/45156018?color=ffb500" width="100%" height="100%" frameborder="0" webkitallowfullscreen="" mozallowfullscreen="" allowfullscreen=""></iframe>
  #       </figure>
  #     </li>
  #     <li>
  #       <figure>
  #         <img src="#{host}/images/demo-screenshots/sc-activity.jpg" />
  #         <p class="flex-caption">Wow! Cool - good luck!<span>Someone we talked to the other day...</span></p>
  #       </figure>
  #     </li>
  #     <li>
  #       <figure>
  #         <img src="#{host}/images/demo-screenshots/sc-code.jpg" />
  #         <p class="flex-caption">I don't get it... What is it, again?<span>Same dude.</span></p>
  #       </figure>
  #     </li>
  #     <li>
  #       <figure>
  #         <img src="#{host}/images/demo-screenshots/sc-apps.jpg" />
  #         <p class="flex-caption">Real software development in the browser...<span>Us again.</span></p>
  #       </figure>
  #     </li>
  #     <li>
  #       <figure>
  #         <img src="#{host}/images/demo-screenshots/sc-apps.jpg" />
  #         <p class="flex-caption">with a real VM and a real Terminal?<span>"and for free? You got to be kidding me..." he added. We gave him a beta invite.</span></p>
  #       </figure>
  #     </li>
  #   </ul>
  #   """