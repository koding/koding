class HomeSlideShowHolder extends JView

  constructor:->

    super

    @slideShow = new HomeSlideShow
      tagName : "section"

    @leftArrow = new KDCustomHTMLView
      tagName  : "a"
      cssClass : "arrow left"
      partial  : "<span></span>"
      click    : => @slideShow.slideTo "prev"

    @rightArrow = new KDCustomHTMLView
      tagName  : "a"
      cssClass : "arrow right"
      partial  : "<span></span>"
      click    : => @slideShow.slideTo "next"

    @slideShow.on "FirstSlideShown", =>
      @rightArrow.$().css right : 0
      @leftArrow.$().css left : -40

    @slideShow.on "LastSlideShown", =>
      @leftArrow.$().css left : 0
      @rightArrow.$().css right : -40

    @slideShow.on "OtherSlideShown", =>
      @leftArrow.$().css left : 0
      @rightArrow.$().css right : 0


  pistachio:->

    # <h1>Isn't it about time to say goodbye to localhost? </h1>
    # <h2>We're a few developers who think there is a better way to work. </h2>
    """
    {{> @leftArrow}}
    {{> @rightArrow}}
    {{> @slideShow}}
    """

class HomeSlideShow extends KDScrollView

  viewAppended:->

    @setTemplate @pistachio()
    @template.update()
    @listenWindowResize()
    @setKeyView()
    @_windowDidResize()
    @slideTo 0

  _windowDidResize:->

    {winHeight, winWidth} = @getSingleton('windowController')
    slideAmount = @$('li').length
    # @setHeight winHeight - @parent.$('h1').height() - @parent.$('h2').height() - 51 - 130
    # @$('ul').css marginTop : @parent.$('h1').height() + @parent.$('h2').height() + 70
    @$('ul').width winWidth * slideAmount
    @$('li').width winWidth

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
        <img src="#{host}/images/demo-screenshots/sc-code.jpg" />
        <p class="flex-caption">A free, fully featured Cloud Development environment. Create and edit code from anywhere.</p>
      </li>
      <li>
        <img src="#{host}/images/demo-screenshots/sc-activity.jpg" />
        <p class="flex-caption">An active community where you can share work, collaborate and meet people who can help you with your projects.</p>
      </li>
      <li>
        <img src="#{host}/images/demo-screenshots/sc-terminal.jpg" />
        <p class="flex-caption">A fully functional Terminal in your browser.</p>
      </li>
      <li>
        <img src="#{host}/images/demo-screenshots/sc-apps.jpg" />
        <p class="flex-caption">An App Catalog to install common web apps, user contributed apps and scripts and more.</p>
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
