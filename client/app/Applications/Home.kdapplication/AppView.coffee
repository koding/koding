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



class HomeMainView extends KDScrollView

  viewAppended:->
    @listenWindowResize()
    # mainController = @getSingleton("mainController")
    @registerListener
      KDEventTypes : "AboutButtonClicked"
      listener     : @
      callback     : (pubInst,event)=>
        @showAboutDisplay()


  putSlideShow:->

    @addSubView @slideHolder = new KDView
      tagName  : "header"
      cssClass : "slide-holder"

    @slideHolder.addSubView slide = new IntroView
      cssClass : "slide"
      delegate : @

    return @slideHolder

  putWidgets:->

    @addSubView @widgetHolder = new HomeWidgetHolder
      cssClass : 'widget-holder clearfix'

    return @widgetHolder

  putTechnologies:->

    @addSubView @technologies = new TechnologyView
      tagName     : 'section'

    return @technologies

  putScreenshotDemo:->

    @addSubView @screenshotDemo  = new ScreenshotDemoView
      tagName     : 'section'

    return @screenshotDemo

  putFooter:->

    @addSubView @footer = new MainPageFooterView
      tagName  : 'footer'
      delegate : @
      cssClass : 'home'
    ,
      about    : no

    return @footer

  _windowDidResize:->
    # h = @getHeight()
    # @slideHolder.setHeight h - 100
    # @footer.setHeight @getHeight() - 880

  showAboutDisplay:->
    if not @aboutIsOpen
      @aboutIsOpen             = yes
      contentDisplayController = @getSingleton "contentDisplayController"
      controller               = new ContentDisplayControllerAbout null, null
      contentDisplay           = controller.getView()
      contentDisplayController.emit "ContentDisplayWantsToBeShown", contentDisplay
      contentDisplayController.on "ContentDisplayWantsToBeHidden", => @aboutIsOpen = no


class IntroView extends KDView
  viewAppended:->
    @setPartial @partial()
    @timer = null
    view = this
    @$('.mainlink.org').bind "mouseenter", (event)->
      view.timer = setTimeout =>
        $('.mainlink.magic').removeClass "anim"
        $(this).next().addClass "anim"
      ,150

    @$('.mainlink.org').bind "mouseleave", (event)->
      clearTimeout view.timer

    @$('.mainlink.magic').bind "mouseleave", (event)->
      $('.mainlink.magic').removeClass "anim"

  partial:->
    """
    <div class="introtext clearfix">
      <div class="mainleft">
        <h1>Say Goodbye to<br/>Local Development</h1>
        <p>Koding is a <span>developer community</span> and <span>cloud development environment</span> that gives you a full stack of collaboration &amp; development tools <span>in your browser</span>.</p>
      </div>
      <div class="mainright">
        <div class="reg mainlink org">Create An Account</div>
        <div class="reg mainlink magic">Create An Account</div>
        <div class="demo mainlink org hidden">Demo The App</div>
        <div class="demo mainlink magic hidden">Demo The App</div>
        <div class="learn mainlink org">Learn More</div>
        <div class="learn mainlink magic">Learn More</div>
      </div>
    </div>
    """

  click:(event)->
    if $(event.target).is('.reg')
      @getSingleton('mainController').loginScreen.slideDown =>
        @getSingleton('mainController').loginScreen.animateToForm "register"
    else if $(event.target).is('.learn')
      homeView = @getDelegate()
      homeView.$().animate scrollTop : homeView.technologies.$().position().top, 400


class HomeWidgetHolder extends KDView

  constructor:->
    super
    loaderOptions =
      size          :
        width       : 30
      loaderOptions :
        color       : "#666666"
        shape       : "spiral"
        diameter    : 30
        density     : 30
        range       : 0.6
        speed       : 1.2
        FPS         : 25

    @membersLoader  = new KDLoaderView loaderOptions
    @activityLoader = new KDLoaderView loaderOptions
    @topicsLoader   = new KDLoaderView loaderOptions
    @countersLoader = new CounterGroupView {},
      Servers   :
        count   : "00000"
      Databases :
        count   : "00000"
      Websites  :
        count   : "00000"

    @moreActivity = new KDCustomHTMLView
      tagName : 'a'
      partial : "Want to See More Activity"
      click   : => @notify()
    @moreTopics = new KDCustomHTMLView
      tagName : 'a'
      partial : "View More Topics?"
      click   : => @notify()
    @moreMembers = new KDCustomHTMLView
      tagName : 'a'
      partial : "View More Members"
      click   : => @notify()

  notify:->
    new KDNotificationView
      title : 'Please login/register!'

  showLoaders:->
    @membersLoader.show()
    @activityLoader.show()
    @topicsLoader.show()
    @countersLoader.show()

  pistachio:->
    """
    <aside>
      <h2>Latest Members</h2>
      {{> @membersLoader}}
      {{> @members}}
      <footer>
        {{> @moreMembers}}
      </footer>
    </aside>
    <section>
      <header>
        <h3>Right Now on Koding</h3>
        {{> @countersLoader}}
      </header>
      {{> @activityLoader}}
      {{> @activity}}
      <footer>
        {{> @moreActivity}}
      </footer>
    </section>
    <aside>
      <h2>Latest Topics</h2>
      {{> @topicsLoader}}
      {{> @topics}}
      <footer>
        {{> @moreTopics}}
      </footer>
    </aside>
    """

class CounterGroupView extends KDCustomHTMLView
  constructor:(options = {},data)->
    options.tagName = "div"
    super options,data

  viewAppended:->
    counters = @getData()
    for title, options of counters
      @setPartial @getCounterHTML title, options.count

    # setInterval =>
    #   partial = ""
    #   for title, options of counters
    #     partial += @getCounterHTML title, options.count++
    #   @updatePartial partial
    # ,1

  getNumbersHTML:(count)->
    str   = count + ""
    group = ""
    for digit in str
      group += "<span>#{digit}</span>"

    return group

  getCounterHTML:(title,count)->
    """
    <div class="acounter">
      <div class="numholder">
        #{@getNumbersHTML count}
      </div>
      #{title}
    </div>
    """

class HomeMemberItemView extends KDListItemView
  constructor:(options,data)->
    options = options ? {}
    options.type = "member"
    super options,data

    @avatar  = new AvatarStaticView
      size        :
        width     : 30
        height    : 30
    , data
    @user    = new ProfileTextView
      tagName : "strong"
    , data

  viewAppended:->
    @setTemplate @pistachio()
    @template.update()


  timeago:(timestamp = 0)->
    $.timeago timestamp

  pistachio:->
    """
    {span.avatar{> @avatar}}
    <p class='right-overflow'>
      {{> @user}}
      {small.hidden{ @timeago #(meta.modifiedAt)}}
    </p>
    """

class HomeTopicItemView extends KDListItemView
  constructor:(options,data)->
    options = options ? {}
    options.type = "topic"
    super options,data

  viewAppended:->
    @setTemplate @pistachio()
    @template.update()

  followerText:(count)->
    if count < 2
      "#{count} Post"
    else
      "#{count} Posts"

  pistachio:->
    """
    {span.fl.ttag{ #(title)}}
    <p class='right-overflow'>
       <small>{{ @followerText #(counts.tagged) or 0}}</small>
    </p>
    """

class HomeActivityItem extends KDListItemView

  getActivityIconCssClass = ->
    JStatusUpdate       : "status"
    JCodeSnip           : "codesnip"
    CFolloweeBucket     : "follower"
    CFollowerBucket     : "followee"
    CNewMemberBucket    : "new-member"

  constructor:(options,data)->
    options = options ? {}
    options.type = "activity"
    super options,data


    if data.anchor?.constructorName is "JTag"
      @user = new ProfileTextView
        tagName           : "strong"
        origin            :
          id              : data.group[0].id
          constructorName : data.group[0].constructorName
        click             : -> no
    else
      @user = new ProfileTextView
        tagName           : "strong"
        origin            :
          id              : data.originId or data.anchor.id
          constructorName : data.originType or data.anchor.constructorName


  getActivityPhrase:(constructorName)->
    data = @getData()
    if data.anchor?.constructorName is "JTag"
      return "has followed a topic."

    switch constructorName
      when "JStatusUpdate"    then "posted a status update."
      when "JCodeSnip"        then "shared some code."
      when "CFolloweeBucket"  then "is being followed."
      when "CFollowerBucket"  then "followed a topic."
      when "CNewMemberBucket" then "became a member."
      else
        "did do something."

  viewAppended:->
    @setTemplate @pistachio()
    @template.update()
    @$('span.icon').addClass getActivityIconCssClass()[@getData().bongo_.constructorName]

  timeago:(timestamp)->
    $.timeago timestamp if timestamp

  pistachio:->
    """
    <span class='icon'></span>
    <p class='right-overflow'>
      {{> @user}}
      {{ @getActivityPhrase #(bongo_.constructorName)}}
      {small{ @timeago #(meta.modifiedAt)}}
    </p>
    """

class TechnologyView extends KDView
  constructor:(options, data)->
    options = $.extend
      domId       : 'technologies'
    , options
    super options, data

  viewAppended:->
    @addSubView techHeader = new KDCustomHTMLView
      tagName     : 'h3'
      partial     : 'Pre-Supported Technologies'

    for technology in @getTechnologies()
      @addSubView techItem = new TechnologyItemView {}, technology

    @addSubView techNote = new KDCustomHTMLView
      tagName     : 'p'
      cssClass    : 'tech-note'
      partial     : 'These technologies are just a starting point for you. We provide you with a linux cloud server for development, so you can install just about anything you want to your environment.'

  getTechnologies:->
    return [
      {
        title       : 'PHP'
        avatar      : '../images/technologies/icphp.png'
      },
      {
        title       : 'Perl'
        avatar      : '../images/technologies/icperl.png'
      },
      {
        title       : 'Python'
        avatar      : '../images/technologies/icpython.png'
      },
      {
        title       : 'Ruby'
        avatar      : '../images/technologies/icruby.png'
      },
      {
        title       : 'NodeJS'
        avatar      : '../images/technologies/icnode.png'
      },
      {
        title       : 'MySQL'
        avatar      : '../images/technologies/icmysql.png'
      },
      {
        title       : 'MongoDB'
        avatar      : '../images/technologies/icmongo.png'
      },
      {
        title       : 'Git'
        avatar      : '../images/technologies/icgit.png'
      }
    ]



class TechnologyItemView extends KDView
  constructor:(options, data)->
    options = $.extend
      tagName     : 'a'
      cssClass    : 'technology-item'
      partial     : '<span class="' + data.title.toLowerCase() + '" />'
      click       :-> noop
    , options
    super options, data


class ScreenshotDemoView extends KDView
  constructor:(options, data)->
    options = $.extend
      cssClass    : 'screenshot-demo'
    , options
    super options, data

  viewAppended:->
    screenshotArray = []
    mainController = @getSingleton('mainController')

    @addSubView ScreenshotHeader = new KDCustomHTMLView
      tagName     : 'h3'
      partial     : 'Screenshot Demo'

    @addSubView ScreenshotSub = new KDCustomHTMLView
      tagName     : 'p'
      cssClass    : 'screenshot-sub'
      partial     : 'Screenshots are cool, but the real app is cooler.'
      click       :(pubInst, event)=>
        if $(event.target).is '.screenshot-login'
          mainController.loginScreen.slideDown =>
            mainController.loginScreen.animateToForm "register"

    for screenshot in @screenshots
      @addSubView screenshotItem = new ScreenshotItemView
        cssClass    : 'screenshot-item'
      , screenshot
      screenshotArray.push screenshotItem

    @registerListener
      KDEventTypes  : "SetScreenshotModal"
      listener      : @
      callback      : (pubInst, {screenshot, itemCalling})=>
        @createScreenshotModal itemCalling, screenshot, screenshotArray

  screenshots:
    [
      {
        title         : 'Online Code Editing'
        description   : 'In-browser coding that feels natural with keyboard shortcuts and syntax highlighting for over 30 programming languages.'
        image         : '../images/demo-screenshots/sc-code.png'
        thumb         : '../images/demo-screenshots/sc-code-thumb.png'
      },
      {
        title         : 'The Koding Community'
        description   : 'Meet developers & collaborate. Follow tags that interest you and learn new things from other members of the Koding Community.'
        image         : '../images/demo-screenshots/sc-activity.png'
        thumb         : '../images/demo-screenshots/sc-activity-thumb.png'
      },
      {
        title         : 'A Free Dev Server + Terminal'
        description   : 'Your free account comes with a real linux development server to run your apps &amp; a real terminal.'
        image         : '../images/demo-screenshots/sc-terminal.png'
        thumb         : '../images/demo-screenshots/sc-terminal-thumb.png'
      },
      {
        title         : 'App Catalog'
        description   : 'Easily install web apps, scripts and Koding add-ons or create your own apps and add them to the catalog.'
        image         : '../images/demo-screenshots/sc-apps.png'
        thumb         : '../images/demo-screenshots/sc-apps-thumb.png'
      }
    ]

  createScreenshotModal:(itemCalling, screenshot, screenshotArray)->
    @newModal = new ScreenshotDemoModalView { parent: itemCalling }, { screenToShow : screenshot, screenshots : @screenshots, allScreenItems : screenshotArray }

class ScreenshotItemView extends KDView
  constructor:->
    super

  viewAppended:->
    @setPartial @partial()
    @prepend screenshotLink = new ScreenshotItemLinkView
      tagName     : 'a'
      cssClass    : 'zoom-shot'
      parent      : @
    , @getData()

  partial:->
    {title, description} = @getData()
    """
      <h4>#{title}</h4><p>#{description}</p>
    """

class ScreenshotItemLinkView extends KDView
  constructor:->
    super

  viewAppended:->
    @setPartial @partial()

  partial:->
    {thumb} = @getData()
    """
      <img src="#{thumb}" />
    """

  click:(event)=>
    @parent.parent.propagateEvent {KDEventType : 'SetScreenshotModal'}, {screenshot : @getData(), itemCalling : @}


class ScreenshotDemoModalView extends KDModalView
  constructor:(options, data)->
    newHeight = Math.floor  options.parent.$('img').height()
    options = $.extend
      cssClass    : 'screenshot-modal'
      height      : newHeight
      width       : Math.floor options.parent.getWidth()
      position    :
        top         : options.parent.getY() - (newHeight + 6)
        left        : options.parent.getX() - 20
      draggable   : no
      overlay     : yes
    , options
    super options, data

  setDomElement:(cssClass)->
    @domElement = $ "
    <div class='kdmodal #{cssClass}'>
      <span class='close-icon closeModal'></span>
    </div>"

  viewAppended:->
    {screenToShow, screenshots} = @getData()
    for screenshot in screenshots
      itemClass = if screenshot.title is screenToShow.title then 'screenshot-modal-item active' else 'screenshot-modal-item'
      @addSubView screenshotModalView = new ScreenshotModalItemView
        cssClass    : itemClass
      , screenshot
    @animateUp()
    @windowController = @getSingleton("windowController")
    @listenWindowResize()

  _windowDidResize:->
    {winWidth, winHeight} = @getSingleton("windowController")
    if (winHeight / winWidth) > .625
      widthToGoTo = winWidth * .8
      heightToGoTo = winHeight * .625
    else
      heightToGoTo = winHeight * .8
      widthToGoTo = heightToGoTo * 1.6
    topToGoTo = (winHeight / 2) - (heightToGoTo / 2) - 10
    leftToGoTo = (winWidth / 2) - (widthToGoTo / 2) - 10
    @$().css
      height    : heightToGoTo
      width     : widthToGoTo
      top       : topToGoTo
      left      : leftToGoTo


  animateUp:->
    # .6282, 1.591
    {winWidth, winHeight} = @getSingleton("windowController")
    if (winHeight / winWidth) > .625
      widthToGoTo = winWidth * .8
      heightToGoTo = widthToGoTo * .628
    else
      heightToGoTo = winHeight * .8
      widthToGoTo = heightToGoTo * 1.591
    topToGoTo = (winHeight / 2) - (heightToGoTo / 2) - 10
    leftToGoTo = (winWidth / 2) - (widthToGoTo / 2) - 10
    @$().delay(200).animate
      height    : heightToGoTo
      width     : widthToGoTo
      top       : topToGoTo
      left      : leftToGoTo
    , 500


  animateDown:(item)->
    modal = @
    newHeight = Math.floor item.$('img').height()
    @$().animate
      height    : newHeight
      width     : Math.floor item.getWidth()
      top       : item.getY() + 10
      left      : item.getX() + 10
    , 500, => modal.destroy()


  setNextScreenshot:(oldScreenshot)->
    {screenshots} = @getData()
    thisOne = no
    for screenshot in screenshots
      if thisOne
        theScreenshot = screenshot
        break
      thisOne = yes if screenshot.title is oldScreenshot.title

    if not theScreenshot?
      theScreenshot = screenshots[0]

    for screenshot in @getSubViews()
      screenshot.setClass 'active' if screenshot.getData().title is theScreenshot.title

  onBeforeDestroy:->
    {allScreenItems} = @getData()
    for screenshot in @getSubViews()
      theScreenshot = screenshot if screenshot.$().hasClass 'active'

    for screenshotItem in allScreenItems
      theReturnSpot = screenshotItem if screenshotItem.getData().title is theScreenshot.getData().title

    @animateDown theReturnSpot

  click:(e)->
    @onBeforeDestroy() if $(e.target).is(".closeModal")
    # @getSingleton("windowController").setKeyView @ ---------> disabled because KDEnterinputView was not working in KDmodal

  keyUp:(e)->
    @onBeforeDestroy() if e.which is 27

  putOverlay:()->
    @$overlay = $("<div/>")
      class : "kdoverlay"
    @$overlay.hide()
    @$overlay.appendTo "body"
    @$overlay.fadeIn 200
    if @getOptions().overlayClick
      @$overlay.bind "click",()=>
        @onBeforeDestroy()

class ScreenshotModalItemView extends KDView
  viewAppended:->
    @setPartial @partial()

  partial:->
    {title, image} = @getData()
    """
      <img src="#{image}" alt="#{title}" />
    """

  click:(event)->
    @unsetClass 'active'
    @parent.setNextScreenshot @getData()
