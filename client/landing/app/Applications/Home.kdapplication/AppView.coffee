class HomeAppView extends KDView

  constructor:(options = {}, data)->

    options.domId    = "home-header"
    options.cssClass = "screenshots"

    super options, data


  viewAppended:->

    account = KD.whoami()
    # @addSubView @header = new WelcomeHeader
    #   domId     : "home-welcome-header"
    #   type      : "big"
    #   title     : if KD.isLoggedIn() then\
    #     "Hi #{account.profile.firstName}! Welcome to the Koding Public Beta." else\
    #     "Welcome to the Koding Public Beta!<br>"
    #   subtitle  : "Warning! when we say beta - <a href='#'>we mean it</a> :)"

    @addSubView @slideShow = new HomeSlideShow
      domId   : "home-slideshow"

    @addSubView @counterBar = new CounterGroupView
      domId    : "home-counter-bar"
      tagName  : "section"
    ,
      "MEMBERS"          : count : 0
      "Virtual Machines" : count : 0
      # "Lines of Code"    : count : 0
      "GROUPS"           : count : 0
      "TOPICS"           : count : 0
      "Thoughts shared"  : count : 0

    vms          = @counterBar.counters["Virtual Machines"]
    # loc          = @counterBar.counters["Lines of Code"]
    members      = @counterBar.counters.MEMBERS
    groups       = @counterBar.counters.GROUPS
    topics       = @counterBar.counters.TOPICS
    activities   = @counterBar.counters["Thoughts shared"]
    vmController = KD.getSingleton("vmController")
    {JAccount, JTag, JGroup, CActivity} = KD.remote.api

    members.ready => JAccount.count "",         (err, count)=> members.update count    or 0
    vms.ready => vmController.fetchTotalVMCount (err, count)=> vms.update count        or 0
    # loc.ready => vmController.fetchTotalLoC     (err, count)=> loc.update count        or 0
    groups.ready => JGroup.count "",            (err, count)=> groups.update count     or 0
    topics.ready => JTag.count "",              (err, count)=> topics.update count     or 0
    activities.ready => CActivity.count "",     (err, count)=> activities.update count or 0

    KD.getSingleton("activityController").on "ActivitiesArrived", (newActivities=[])->
      activities.increment newActivities.length

    @addSubView @homeLoginBar = new HomeLoginBar
      domId    : "home-login-bar"

    @utils.wait 500, => @_windowDidResize()
    KD.getSingleton("contentPanel").on "transitionend", (event)=>
      event.stopPropagation()
      @_windowDidResize()  if $(event.target).is "#content-panel"

  _windowDidResize:->
    @unsetClass "extra-wide wide medium narrow extra-narrow"
    w = @getWidth()
    @setClass if w > 1500    then ""
    else if 1000 < w < 1500  then "extra-wide"
    else if 800  < w < 1000  then "wide"
    else if 600  < w < 800   then "medium"
    else if 480  < w < 600   then "narrow"
    else "extra-narrow"

  # OLD HOME PISTACHIO
  # left here for reference - SY

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




