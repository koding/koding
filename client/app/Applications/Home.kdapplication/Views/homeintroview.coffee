class HomeIntroView extends JView

  constructor:(options = {}, data)->

    # options.tagName or= "section"
    options.domId   or= "home-intro"

    super options, data

    router = KD.getSingleton 'router'

    @slogan = new KDCustomHTMLView
      tagName  : 'h2'
      cssClass : 'slogan'
      partial  : 'A new way for<br/>developers to work.'

    @subSlogan = new KDCustomHTMLView
      tagName  : 'h3'
      cssClass : 'slogan-continues'
      partial  : """
                <span>Software development has finally evolved.</span>
                <br>
                <span>It's now social, in the browser and free.</span>
                """

    @github = new KDButtonView
      title       : 'Sign up with GitHub'
      cssClass    : 'register gh-gray'
      type        : 'button'
      icon        : yes
      iconClass   : 'octocat'
      callback    : -> KD.singletons.oauthController.openPopup "github"

    @signup = new KDButtonView
      title       : 'Sign up with email'
      cssClass    : 'register orange'
      type        : 'button'
      testPath    : "landing-register-email"
      callback    : -> router.handleRoute '/Register'

    @tos = new KDCustomHTMLView
      cssClass : 'tos'
      partial  : 'By signing up, you agree to our <a href="/tos.html" target="_blank">terms of service</a> and <a href="/privacy.html" target="_blank">privacy policy</a>.'


    @twoMinsThumb = new KDCustomHTMLView
      tagName  : 'a'
      partial  : "<i></i><img src='/images/video/twomins.jpg'/>"
      click    : ->
        w = 800
        h = 450
        window.open "/twomins.html",
          "Koding and the Timedude!",
          "width=#{w},height=#{h},left=#{Math.floor (screen.width/2) - (w/2)},top=#{Math.floor (screen.height/2) - (h/2)}"

    @timedudeThumb = new KDCustomHTMLView
      tagName  : 'a'
      partial  : "<i></i><img src='/images/video/timedude.jpg'/>"
      click    : ->
        w = 800
        h = 450
        window.open "/timedude.html",
          "Koding and the Timedude!",
          "width=#{w},height=#{h},left=#{Math.floor (screen.width/2) - (w/2)},top=#{Math.floor (screen.height/2) - (h/2)}"

    @try = new KDCustomHTMLView
      tagName    : 'a'
      cssClass   : 'try'
      partial    : 'Go ahead & try!'
      attributes :
        href     : '/Develop'
      click      : (event)->
        KD.utils.stopDOMEvent event
        KD.getSingleton('router').handleRoute "/Develop"

    @counterBar = new CounterGroupView
      domId    : "home-counter-bar"
      tagName  : "section"
    ,
      "MEMBERS"          : count : 0
      "RUNNING VMS"      : count : 0
      # "Lines of Code"    : count : 0
      "GROUPS"           : count : 0
      "TOPICS"           : count : 0
      "Thoughts shared"  : count : 0

    @bindCounters()

  bindCounters:->
    vms          = @counterBar.counters["RUNNING VMS"]
    # loc          = @counterBar.counters["Lines of Code"]
    members      = @counterBar.counters.MEMBERS
    groups       = @counterBar.counters.GROUPS
    topics       = @counterBar.counters.TOPICS
    activities   = @counterBar.counters["Thoughts shared"]
    vmController = KD.getSingleton("vmController")
    {JAccount, JTag, JGroup, CActivity} = KD.remote.api

    members.ready =>
      JAccount.fetchCachedUserCount (err, count)=>
        members.update count or 0

    vms.ready        => vmController.fetchTotalVMCount (err, count)=> vms.update count            or 0
    groups.ready     => JGroup.count                   (err, count)=> groups.update count         or 0
    topics.ready     => JTag.fetchCount                (err, count)=> topics.update count         or 0
    activities.ready => CActivity.fetchCount           (err, count)=> activities.update count     or 0
    # loc.ready        => vmController.fetchTotalLoC     (err, count)=> loc.update count        or 0

    KD.getSingleton("mainController").ready ->
      KD.getSingleton("activityController").on "ActivitiesArrived", (newActivities=[])->
        activities.increment newActivities.length

  show:-> @unsetClass 'out'

  hide:-> @setClass 'out'

  viewAppended:->
    super
    # @utils.wait 2000, => @try.setClass 'in'

  pistachio:->
    inFrame = KD.runningInFrame()
    if KD.isLoggedIn()
      """
      <section>
        <div>
          {{> @slogan}}
          {{> @subSlogan}}
        </div>
        <aside>
          <ul>
            <li>{{> @timedudeThumb}}</li>
          </ul>
        </aside>
      </section>
      {{> @try}}
      {{> @counterBar}}
      """
    else
      """
      <section>
        <div>
          {{> @slogan}}
          {{> @subSlogan}}
        </div>
        <aside>
          <form>
            <div class='formline gh #{'hidden' if inFrame}'>{{> @github}}</div>
            <div class='formline or #{'hidden' if inFrame}'>or</div>
            <div class='formline signup'>{{> @signup}}</div>
            <div class='formline or'>or check what Koding is:</div>
            <ul class='large'>
              <li>{{> @twoMinsThumb}}</li>
              <li>{{> @timedudeThumb}}</li>
            </ul>
            <div class='formline'>{{> @tos}}</div>
          </form>
        </aside>
      </section>
      {{> @try}}
      {{> @counterBar}}
      """



    # @form = new KDFormViewWithFields
    #   fields          :
    #     github        :
    #       name        : 'gh'
    #       title       : 'Sign up with GitHub'
    #       itemClass   : KDButtonView
    #       cssClass    : 'register gh-gray'
    #       type        : 'button'
    #       icon        : yes
    #       iconClass   : 'octocat'
    #     separator     :
    #       name        : 'or'
    #       partial     : 'or'
    #       itemClass   : KDCustomHTMLView
    #     register      :
    #       title       : 'Sign up with e-mail'
    #       itemClass   : KDButtonView
    #       cssClass    : 'register orange'
    #       type        : 'button'
    #       callback    : -> router.handleRoute '/Register'
        # separator     :
        #   name        : 'or'
        #   partial     : 'or'
        #   itemClass   : KDCustomHTMLView
        # login         :
        #   tagName     : 'span'
        #   itemClass   : KDButtonView
        #   title       : 'Already a user? Login'
        #   cssClass    : 'login gray'
        #   type        : 'button'
        #   callback    : -> router.handleRoute '/Login'
        # firstname     :
        #   name        : 'firstname'
        #   placeholder : 'First name'
        #   cssClass    : 'half'
        #   nextElement     :
        #     lastname      :
        #       name        : 'lastname'
        #       placeholder : 'Last name'
        #       cssClass    : 'half'
        # username      :
        #   name        : 'username'
        #   placeholder : 'Desired username'
        # email         :
        #   name        : 'email'
        #   placeholder : 'Your email address'
        #   type        : 'email'
        # password      :
        #   name        : 'password'
        #   placeholder : 'Type a password'
        #   type        : 'password'
      # buttons         :

    # @videoThumb = new KDCustomHTMLView
    #   tagName  : 'a'
    #   partial  : "<i></i><img src='/images/timedude.jpg'/>"
    #   click    : ->
    #     w = 800
    #     h = 450
    #     window.open "/timedude.html",
    #       "Koding and the Timedude!",
    #       "width=#{w},height=#{h},left=#{Math.floor (screen.width/2) - (w/2)},top=#{Math.floor (screen.height/2) - (h/2)}"

