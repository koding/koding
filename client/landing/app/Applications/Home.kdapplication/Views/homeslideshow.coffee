class HomeSlideShow extends KDView

  constructor:(options = {}, data)->
    
    host = unless /koding\.com/.test location.hostname then "" else "https://api.koding.com"
    data = [
      {
        bg      : "#{host}/images/bg/blurred/1.jpg"
        title   : "<p><span>A new way for</span><br><span>developers to work.</span></p>"
      },{
        bg      : "#{host}/images/bg/blurred/2.jpg"
        title   : "<p><span>Real software development</span><br><span>in the browser...</span></p>"
      },{
        bg      : "#{host}/images/bg/blurred/3.jpg"
        title   : "<p><span>with a great community </span><br><span>of developers...</span></p>"
      },{
        bg      : "#{host}/images/bg/blurred/4.jpg"
        title   : "<p><span>with a real VM and </span><br><span>a real Terminal...</span></p>"
      },{
        bg      : "#{host}/images/bg/blurred/5.jpg"
        title   : "<p><span>and free for all...</span></p>"
      },{
        bg      : "#{host}/images/bg/blurred/7.jpg"
        title   : """
          <figure class='video'>
            <iframe src="https://player.vimeo.com/video/45156018?color=ffb500" width="100%" height="100%" frameborder="0" webkitallowfullscreen="" mozallowfullscreen="" allowfullscreen=""></iframe>
          </figure>
        """
      }
    ]
    options.tagName or= "section"
    options.keydown   = 
      left  : @slideTo.bind this, "prev"
      right : @slideTo.bind this, "next"

    super options, data
    
    @slides = []
    @pos    = 0
    @listenWindowResize()

  viewAppended:->
    @leftArrow = new KDCustomHTMLView
      domId    : "home-ss-left-arrow"
      tagName  : "a"
      cssClass : "arrow left"
      partial  : "<span></span>"
      click    : (event)=>
        @utils.stopDOMEvent event
        @slideTo "prev"

    @leftArrow.setX -40

    @rightArrow = new KDCustomHTMLView
      domId    : "home-ss-right-arrow"
      tagName  : "a"
      cssClass : "arrow right"
      partial  : "<span></span>"
      click    : (event)=>
        @utils.stopDOMEvent event
        @slideTo "next"

    @wrapper = new KDScrollView
      cssClass   : 'clearfix'
      tagName    : 'ul'
      bind       : 'mousewheel'
      mousewheel : =>
        @utils.killWait @timer
        @timer = @utils.wait 300, => @slideTo()

    for slide, i in @getData()
      @wrapper.addSubView slide = new KDCustomHTMLView
        tagName    : 'li'
        partial    : slide.title
        cssClass   : "to-right" if i > 0
        attributes :
          style    : "background-image: url('#{slide.bg}'); left: #{i*100}%"
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

  _windowDidResize:->

    @slides.forEach (slide, i)->
      slide.$().css left : "#{i*100}%"

  click:-> @setKeyView()

  slideTo:(index)->

    addend = switch index
      when "prev" then -1
      when "next" then 1
      else 0
    index  = null if addend isnt 0
    amount = @slides.length
    aWidth = 100 / amount
    pos    = index or @pos
    pos    = pos + addend

    if pos < 0 
    then pos = 0
    else if pos > amount-1
    then pos = amount - 1
    log "????", pos, @pos
    for slide, i in @slides when i isnt pos
      if pos < i
        slide.unsetClass 'to-left'
        slide.setClass 'to-right'
      else
        slide.setClass 'to-left'
        slide.unsetClass 'to-right'

    @pos = pos
    @slides[pos].unsetClass 'to-left to-right'
    @wrapper.$().animate scrollLeft : (pos * (@wrapper.getScrollWidth() * aWidth / 100)), 300

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