class HomeSlideShow extends KDScrollView

  constructor:->

    super

    @pos = 0

  viewAppended:->

    @setTemplate @pistachio()
    @template.update()
    @listenWindowResize()
    @setKeyView()
    @_windowDidResize()
    @slideTo 0

    @getSingleton('mainView').on "transitionend", @bound "_windowDidResize"

  _windowDidResize:->

    {winHeight, winWidth} = @getSingleton('windowController')
    slideAmount = @$('>ul>li').length
    {contentPanel} = @getSingleton('mainView')
    @$('>ul').width "#{slideAmount}00%"
    @$('>ul>li').width "#{100/slideAmount}%"
    aWidth = @$('>ul>li>*').first().width()
    @$('>ul>li>p').css
      width      : aWidth
      marginLeft : -(aWidth / 2)

  click:->
    @setKeyView()

  keyDown:(event)->
    switch event.which
      when 37 then @slideTo "prev"
      when 39 then @slideTo "next"

  mouseWheel:(event)->

    @utils.killWait @timer
    @timer = @utils.wait 300, => @slideTo()

  slideTo:(index)->

    addend = switch index
      when "prev" then -1
      when "next" then 1
      else 0
    index  = null if addend isnt 0
    amount = @$('>ul>li').length
    aWidth = 100 / amount
    pos    = index or @pos
    pos    = pos + addend

    if pos < 0 then pos = 0
    else if pos > amount-1 then pos = amount - 1

    @pos = pos

    @$().animate scrollLeft : (pos * (@getScrollWidth() * aWidth / 100)), 277

    if pos is 0
      @emit "FirstSlideShown"
    else if pos is amount-1
      @emit "LastSlideShown"
    else
      @emit "OtherSlideShown"


  pistachio:->

    host = unless /koding\.com/.test location.hostname then "" else "https://api.koding.com"
    """
    <ul class="clearfix">
      <li>
        <figure>
          <img src="#{host}/images/demo-screenshots/sc-terminal.jpg" />
          <p class="flex-caption">A new way for developers to work.<span>We said.</span></p>
        </figure>
      </li>
      <li>
        <figure class='video'>
          <iframe src="https://player.vimeo.com/video/45156018?color=ffb500" width="100%" height="100%" frameborder="0" webkitallowfullscreen="" mozallowfullscreen="" allowfullscreen=""></iframe>
        </figure>
      </li>
      <li>
        <figure>
          <img src="#{host}/images/demo-screenshots/sc-activity.jpg" />
          <p class="flex-caption">Wow! Cool - good luck!<span>Someone we talked to the other day...</span></p>
        </figure>
      </li>
      <li>
        <figure>
          <img src="#{host}/images/demo-screenshots/sc-code.jpg" />
          <p class="flex-caption">I don't get it... What is it, again?<span>Same dude.</span></p>
        </figure>
      </li>
      <li>
        <figure>
          <img src="#{host}/images/demo-screenshots/sc-apps.jpg" />
          <p class="flex-caption">Real software development in the browser...<span>Us again.</span></p>
        </figure>
      </li>
      <li>
        <figure>
          <img src="#{host}/images/demo-screenshots/sc-apps.jpg" />
          <p class="flex-caption">with a real VM and a real Terminal?<span>"and for free? You got to be kidding me..." he added. We gave him a beta invite.</span></p>
        </figure>
      </li>
    </ul>
    """