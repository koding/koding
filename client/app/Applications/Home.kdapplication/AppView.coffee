class HomeAppView extends JView

  constructor:->

    super

    @setClass "screenshots"

    account = KD.whoami()

    @header = new WelcomeHeader
      type      : "big"
      title     : if KD.isLoggedIn() then\
        "Hi #{account.profile.firstName}! Welcome to the Koding Public Beta." else\
        "Welcome to the Koding Public Beta!<br>"
      subtitle  : "Warning! when we say beta - <a href='#'>we mean it</a> :)"

    @slideShow = new HomeSlideShow
      tagName : "section"

    @leftArrow = new KDCustomHTMLView
      tagName  : "a"
      cssClass : "arrow left"
      partial  : "<span></span>"
      click    : (event)=>
        @utils.stopDOMEvent event
        @slideShow.slideTo "prev"

    @rightArrow = new KDCustomHTMLView
      tagName  : "a"
      cssClass : "arrow right"
      partial  : "<span></span>"
      click    : (event)=>
        @utils.stopDOMEvent event
        @slideShow.slideTo "next"

    @homeLoginBar = new HomeLoginBar

    @slideShow.on "FirstSlideShown", =>
      @rightArrow.$().css right : 0
      @leftArrow.$().css  left  : -40

    @slideShow.on "LastSlideShown", =>
      @leftArrow.$().css  left  : 0
      @rightArrow.$().css right : -40

    @slideShow.on "OtherSlideShown", =>
      @leftArrow.$().css  left  : ""
      @rightArrow.$().css right : ""


  pistachio:->

    """
    {{> @header}}
    {{> @leftArrow}}
    {{> @rightArrow}}
    {{> @slideShow}}
    {{> @homeLoginBar}}
    """


class HomeLoginBar extends JView

  constructor:(options = {}, data)->

    options.cssClass = "home-links"

    super options, data

    if KD.config.profileEntryPoint? or KD.config.groupEntryPoint?
      entryPoint = KD.config.profileEntryPoint or KD.config.groupEntryPoint
    else entryPoint = ''

    handler = (event)->
      route = this.$()[0].getAttribute 'href'
      route = "/#{entryPoint}#{route}" if entryPoint isnt ''
      @utils.stopDOMEvent event
      @getSingleton('router').handleRoute route

    @register     = new CustomLinkView
      tagName     : "a"
      cssClass    : "register"
      title       : "Register an Account"
      icon        : {}
      attributes  :
        href      : "/Register"
      click       : handler

    @browse       = new CustomLinkView
      tagName     : "a"
      cssClass    : "browse orange"
      title       : "Learn more..."
      icon        : {}
      attributes  :
        href      : ""
      click       : (event)=>
        @utils.stopDOMEvent event
        @getSingleton('mainViewController').emit "browseRequested"

    @request      = new CustomLinkView
      tagName     : "a"
      cssClass    : "join green"
      title       : "Request an Invite"
      icon        : {}
      attributes  :
        href      : "/Join"
      click       : handler

    @login        = new CustomLinkView
      tagName     : "a"
      title       : "Login"
      icon        : {}
      cssClass    : "login"
      attributes  :
        href      : "/Login"
      click       : (event)=>
        @utils.stopDOMEvent event
        @getSingleton('router').handleRoute "/Login"

  pistachio:-> "{{> @browse}}{{> @request}}{{> @register}}{{> @login}}"

  # pistachio:->

  #   """
  #   <div class="kdview video-wrapper">
  #     <iframe src="https://player.vimeo.com/video/45156018?color=ffb500" width="89.13%"
  #     height="76.60%" frameborder="0" webkitallowfullscreen="" mozallowfullscreen=""
  #     allowfullscreen="">
  #     </iframe>
  #   </div>
  #   <div class="home-links">
  #     <p class="bigLink">{{> @request}}</p>
  #     <p class="bigLink">{{> @register}}</p>
  #     <p class="bigLink">{{> @login}}</p>
  #     <p class="bigLink">{{> @learn}}</p>
  #   </div>
  #   <section>
  #     <hr id="home-reviews">
  #     <div class="reviews">
  #       <p>A new way for developers to work</p>
  #       <span>We said.</span>
  #       <p>Wow! Cool - good luck!</p>
  #       <span>Someone we talked to the other day...</span>
  #       <p>I don't get it... What is it, again?</p>
  #       <span>Same dude.</span>
  #       <p>Real software development in the browser...</p>
  #       <span>Us again.</span>
  #       <p>with a real VM and a real Terminal?</p>
  #       <span>"and for free? You got to be kidding me..." he added. We gave him a beta invite.</span>
  #     </div>
  #     <hr />
  #     <div id="home-screenshots" class="screenshots">
  #       <div class="kdview">
  #         {{> @leftArrow}}
  #         {{> @rightArrow}}
  #         {{> @slideShow}}
  #       </div>
  #     </div>
  #     <hr />
  #     <footer id="copy-footer" class="copy">
  #       ©#{(new Date).getFullYear()} Koding, Inc. 358 Brannan Street, San Francisco, CA 94107
  #     </footer>

  #   </section>
  #   """

class HomeSlideShow extends KDScrollView

  viewAppended:->

    @setTemplate @pistachio()
    @template.update()
    @listenWindowResize()
    @setKeyView()
    @_windowDidResize()
    @slideTo 0

    @getSingleton('mainView').on "transitionend", =>
      @_windowDidResize()

  _windowDidResize:->

    {winHeight, winWidth} = @getSingleton('windowController')
    slideAmount = @$('li').length
    # @setHeight winHeight - @parent.$('h1').height() - @parent.$('h2').height() - 51 - 130
    # @$('ul').css marginTop : @parent.$('h1').height() + @parent.$('h2').height() + 70
    {contentPanel} = @getSingleton('mainView')
    @$('ul').width contentPanel.getWidth() * slideAmount
    @$('li').width contentPanel.getWidth()

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
    total  = @getScrollWidth()
    actual = @$().scrollLeft()
    amount = @$('li').length
    one    = total / amount
    pos    = index or Math.round actual / one
    pos    = pos + addend

    if pos < 0 then pos = 0
    else if pos > amount-1 then pos = amount-1

    @$().animate scrollLeft : pos * one, 500

    # @$('li').removeClass "in"
    # @$('li').eq(pos).addClass "in"

    if pos is 0
      @emit "FirstSlideShown"
    else if pos is amount-1
      @emit "LastSlideShown"
    else
      @emit "OtherSlideShown"


  pistachio:->

    host = unless /koding.com/.test location.hostname then "" else "https://api.koding.com"
    """
    <ul class="clearfix">
      <li>
        <div>
          <iframe src="https://player.vimeo.com/video/45156018?color=ffb500" width="100%" height="100%" frameborder="0" webkitallowfullscreen="" mozallowfullscreen="" allowfullscreen=""></iframe>
        </div>
      </li>
      <li>
        <img src="#{host}/images/demo-screenshots/sc-code.jpg" />
        <p class="flex-caption">A new way for developers to work.<span>We said.</span></p>
      </li>
      <li>
        <img src="#{host}/images/demo-screenshots/sc-activity.jpg" />
        <p class="flex-caption">Wow! Cool - good luck!<span>Someone we talked to the other day...</span></p>
      </li>
      <li>
        <img src="#{host}/images/demo-screenshots/sc-terminal.jpg" />
        <p class="flex-caption">I don't get it... What is it, again?<span>Same dude.</span></p>
      </li>
      <li>
        <img src="#{host}/images/demo-screenshots/sc-apps.jpg" />
        <p class="flex-caption">Real software development in the browser...<span>Us again.</span></p>
      </li>
      <li>
        <img src="#{host}/images/demo-screenshots/sc-apps.jpg" />
        <p class="flex-caption">with a real VM and a real Terminal?<span>"and for free? You got to be kidding me..." he added. We gave him a beta invite.</span></p>
      </li>
    </ul>
    """


# class CounterGroupView extends KDCustomHTMLView
#   constructor:(options = {},data)->
#     options.tagName = "div"
#     super options,data

#   viewAppended:->
#     counters = @getData()
#     for title, options of counters
#       @setPartial @getCounterHTML title, options.count

#     # setInterval =>
#     #   partial = ""
#     #   for title, options of counters
#     #     partial += @getCounterHTML title, options.count++
#     #   @updatePartial partial
#     # ,1

#   getNumbersHTML:(count)->
#     str   = count + ""
#     group = ""
#     for digit in str
#       group += "<span>#{digit}</span>"

#     return group

#   getCounterHTML:(title,count)->
#     """
#     <div class="acounter">
#       <div class="numholder">
#         #{@getNumbersHTML count}
#       </div>
#       #{title}
#     </div>
#     """
