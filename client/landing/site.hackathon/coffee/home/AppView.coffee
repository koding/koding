CustomLinkView   = require './../core/customlinkview'
HomeRegisterForm = require './registerform'

JUDGES           =
  'Kirill Sheynkman' :
    imgUrl       : 'https://pbs.twimg.com/profile_images/1826751334/ksheadright-web_400x400.jpg'
    title        : 'RTP VC - Managing Director'

  'Sinan Yasar'  :
    imgUrl       : 'https://s.gravatar.com/avatar/fb9edfce4f54230c890431a97db6c99e?s=400'
    title        : 'Koding - lead UI/UX & co-founder'

  'Jason Yeh'  :
    imgUrl       : 'http://greycroft.com/wp-content/uploads/2014/06/jason-yeh.jpg'
    title        : 'Greycroft - Senior Associate'

  'Devrim Yasar' :
    imgUrl       : 'https://pbs.twimg.com/profile_images/378800000863144334/uZWGPcJz.jpeg'
    title        : 'Koding - ceo & co-founder'


module.exports = class HomeView extends KDView

  getStats = ->

    KD.campaignStats ?=
      cap                : 50000
      prize              : 10000
      totalApplicants    : 34512
      approvedApplicants : 12521
      isApplicant        : no
      isApproved         : no
      isWinner           : no

  constructor: (options = {}, data)->

    super options, data

    @setPartial @partial()
    @createJudges()
    @createJoinForm()

    scroller = new KDCustomHTMLView
      tagName : 'figure'
      click   : ->
        $(document.body).animate
          scrollTop : window.innerHeight - 50
          easing    : 'ease-out'
          duration  : 177

    @addSubView scroller, '.introduction'

    KD.singletons.windowController.on 'ScrollHappened', ->
      if window.scrollY > 50
      then scroller.setClass 'out'
      else scroller.unsetClass 'out'


  createJoinForm : ->
    {router} = KD.singletons


    if KD.isLoggedIn()
    then @createApplyWidget()
    else

      @signUpForm = new HomeRegisterForm
        cssClass    : 'login-form register no-anim'
        buttonTitle : 'SIGN UP'
        callback    : (formData) =>
          router.requireApp 'Login', (controller) =>
            controller.getView().showExtraInformation formData, @signUpForm

      @addSubView @signUpForm, '.form-wrapper'


  createApplyWidget: ->

    {firstName, lastName, nickname, hash} = KD.whoami().profile
    {isApplicant, isApproved, isWinner} = getStats()

    @addSubView (@section = new KDCustomHTMLView
      tagName  : 'section'
      cssClass : 'logged-in'
    ), '.form-wrapper'

    size     = 80
    fallback = "https://koding-cdn.s3.amazonaws.com/square-avatars/default.avatar.#{size}.png"

    @section.addSubView avatarBg = new KDCustomHTMLView
      cssClass   : 'avatar-background'

    avatarBg.addSubView avatar = new KDCustomHTMLView
      tagName    : 'img'
      cssClass   : 'avatar'
      attributes :
        src      : "//gravatar.com/avatar/#{hash}?size=#{size}&d=#{fallback}&r=g"

    @section.addSubView label = new KDLabelView
      title : "Hey, #{firstName or nickname}!"

    label.addSubView notYou = new CustomLinkView
      title : '(not you?)'
      href  : '/Logout'
      click : (event) ->
        KD.utils.stopDOMEvent event
        document.cookie = 'clientId=null'
        location.replace '/WFGH'

    return if isApplicant

    @section.addSubView button = new KDButtonView
      cssClass : 'apply-button solid green medium'
      title    : 'APPLY NOW'
      loader   : yes
      callback : =>
        $.ajax
          url         : '/WFGH/Apply'
          type        : 'POST'
          xhrFields   : withCredentials : yes
          success     : (stats) =>
            button.hideLoader()
            KD.campaignStats = stats
            @updateWidget()
          error       : (xhr) ->
            {responseText} = xhr
            button.hideLoader()
            new KDNotificationView title : responseText


  updateWidget : ->

    @section.destroy()
    @updateGreeting()
    @updateStats()
    @createApplyWidget()
    @createShareButtons()


  createShareButtons: ->

    @section.setPartial """
      <ul class="social-buttons clearfix">
        <li>
            <a href="http://twitter.com/share" class="socialite twitter-share" data-text="JOIN THE WORLD'S FIRST GLOBAL HACKATHON #WFGH @koding" data-url="http://koding.com/WFGH" data-count="none" rel="nofollow" target="_blank"><span class="vhidden">Share on Twitter</span></a>
        </li>
        <li>
            <a href="https://plus.google.com/share?url=http://koding.com/WFGH" data-annotation="none" class="socialite googleplus-one" data-size="tall" data-href="http://koding.com/WFGH" rel="nofollow" target="_blank"><span class="vhidden">Share on Google+</span></a>
        </li>
        <li>
            <a href="http://www.facebook.com/sharer.php?u=http://koding.com/WFGH&t=JOIN THE WORLD'S FIRST GLOBAL HACKATHON #WFGH @koding" class="socialite facebook-like" data-colorscheme="light" data-href="http://koding.com/WFGH" data-send="false" data-layout="button" data-width="60" data-show-faces="false" rel="nofollow" target="_blank"><span class="vhidden">Share on Facebook</span></a>
        </li>
        <li>
            <a href="http://www.linkedin.com/shareArticle?mini=true&url=http://koding.com/WFGH&title=JOIN THE WORLD'S FIRST GLOBAL HACKATHON #WFGH @koding" data-annotation="none" class="socialite linkedin-share" data-url="http://koding.com/WFGH" data-counter="none" rel="nofollow" target="_blank"><span class="vhidden">Share on LinkedIn</span></a>
        </li>
      </ul>
      """

    Socialite.load @$('ul.social-buttons')[0]


  createJudges : ->

    for name, content of JUDGES
      do =>
        view = new KDCustomHTMLView
          cssClass    : 'judge'

        view.addSubView new KDCustomHTMLView
          tagName     : 'figure'
          attributes  :
            style     : "background-image:url(#{content.imgUrl});"

        view.addSubView new KDCustomHTMLView
          cssClass    : 'info'
          partial     : "#{name} <span>#{content.title}</span>"

        @addSubView view, '.judges > div'


  viewAppended : ->

    super

    @updateGreeting()

    video = document.getElementById 'bgVideo'
    video.addEventListener 'loadedmetadata', ->
      @currentTime = 8
      @playbackRate = .7
    , no

  updateStats: -> @$('div.counters').html @getStats()

  getStats: ->

    { cap, prize, totalApplicants, approvedApplicants } = getStats()

    return """
      PRIZE: <span>$#{prize.toLocaleString()}</span>
      TOTAL SLOTS: <span>#{cap.toLocaleString()}</span>
      APPLICATIONS: <span>#{totalApplicants.toLocaleString()}</span>
      APPROVED APPLICANTS: <span>#{approvedApplicants.toLocaleString()}</span>
      """


  updateGreeting: ->

    { isApplicant, isApproved, isWinner } = getStats()

    if isApplicant and not isApproved
      greeting = 'We received your application, check back later to see if you\'re approved!'

    if isApplicant and isApproved
      greeting = 'CONGRATULATIONS! you are in!'

    if isApplicant and isWinner
      greeting = 'WOHOOOO! You are the WINNER!'

    @$('.introduction > h3').first().html greeting  if greeting


  partial: ->

    """
    <section class="introduction">
      <video id="bgVideo" autoplay loop muted playbackspeed="0.1">
        <source src="./a/site.hackathon/images/intro-bg.webm" type="video/webm">
      </video>
      <h2>
        JOIN THE WORLD’S FIRST GLOBAL HACKATHON <span>#WFGH</span>
      </h2>
      <h3>Announcing the world's first global virtual hackathon. Let's hack together! <br>
          Join today and save your spot <strong>to win $10,000 in cash prizes.</strong></h3>
      <div class="form-wrapper clearfix"></div>
    </section>
    <div class="counters">#{@getStats()}</div>
    <section class="content">
      <article>
        <h4>Developers of the World</h4>
        <br>
        <h5>Let's Hack Together!</h5>
        <p>Traditional hackathons are all about the location and although we love the good old 
        fashioned way of hacking together an awesome project, our browsers are now strong enough 
        that distance is of no consequence when it comes to creating awesome projects. We can 
        and should get together to write code and create awesome projects, regardless of 
        where we are.
        </p>
        <p>Welcome to the World’s First Global Hackathon (#wfgh)!</p>

        <p>This event is intended to connect developers across the globe and get them to  code 
        together irrespective of their locations. You will problem solve and build with old or 
        new team members and try to win!
        </p>
      </article>
      <article>
        <h4>How does it work? </h4>

        <p> First, sign up using the simple form above. We will send you a short questionnaire 
        that will help us understand a little bit more about you and your team’s background.  
        We promise to keep it short and sweet.
        </p>
        
        <p>Applications can come from individuals or teams of up to 5, however each team member 
        needs to be a contributing team member (writing code or designing). If you are an 
        individual who is selected and are looking for team members, post a message on the
        <a href="https://koding.com/Activity/Topic/wfgh" target=_blank>#wfgh channel on Koding</a>. 
        Your post should clearly articulate what type of skill set you are looking for and what 
        type of skill set you have. e.g.: <i>I am a nodeJS developer looking for a backend 
        database team member.</i> Once you get a response, jump into private chats on Koding 
        itself to discuss your ideas and start recruiting!
      </article>
      <article>
        <h4>How do I get accepted? </h4>
        <p>We expect a lot of you to apply but to keep things sane, we will be limiting the 
        final competition to a 1000 teams. Our panel of judges will decide who will be part 
        of the competition. Their decision will be based on factors like location, team size, 
        project work on github, social presence, etc. Applications are being reviewed on a first 
        come first serve basis so apply today and if approved, you will receive an email from 
        us with further instructions. We will also let you know if your application is not approved.
        </p>
      </article>
      <article>
      <h4>What is the theme for the Hackathon?</h4>
      <p>48 hours before the start of the event, we will provide a theme for the event. Your task 
      will be to use the API’s of one (or more) of our API partners and create a project that 
      addresses the theme of the event. The theme will be announced on the 
      <a href="https://koding.com/Activity/Topic/wfgh" target=_blank>#wfgh channel on Koding</a>
       so make sure and mark your calendars!
      </article>
      <article>
        <h4> What are the rules?</h4>
        <p>Our goal is to ensure that all teams have a level playing field; therefore it is 
        imperative that all code, design, assets, etc… must be created during the duration
        of the event. No exceptions. You can brainstorm ideas prior to the event, however 
        any assets or code used as part of your submission must have been created during the event. 
        The only exception to this rule is the usage of publicly available material. This includes: 
        public code snippets, images, open source libraries and projects, public APIs, etc. You 
        get the picture. Play fair!
        </p>
        <p>
        <i>Note: If your team qualifies for a prize, you are automatically subject to a code 
        and asset review to ensure that the above rule has been adhered to.
        </i>    
      </article>
      <article>
        <h4>What are the prizes?</h4>
        <ol>
        <li>$10,000 cash prize from Koding, split amongst 1 to 3 teams (100%, 70%-30%, 50%-30%-20%)</li>
        <li>The top prize winners will be offered interviews with investors on our judging panel 
        (RTP Ventures and Greycroft Partners).</li>
        <li>More to come!</li>
        </ol>
      </article>
      <article>
        <h4>Who will eventually own the projects created?</h4>

        <p>You will retain full ownership and rights to your creation. Be super awesome and have fun! Get 
        creative, meet new people, make new friends and problem solve with them.
        </p>
      </article>
      <article>
        <h4>What is the schedule?</h4>
        <ul>
          <li>Now - Registration open.</li>
          <li>Nov 16th - Applications are closed. Final notifications are sent to teams/individuals who were accepted.</li>
          <li>Nov 18th, 1000 PDT - Hackathon theme is announced on the  <a href="https://koding.com/Activity/Topic/wfgh" target=_blank>#wfgh channel on Koding</a></li>
          <li>Nov 22th - Day 1 Let the hacking begin!</li>
          <li>Nov 23rd - Day 2 of the Hackathon
            <ul>
              <li>0000 – 2200 PDT Hacking continues</li>
              <li>2330 – 0000 PDT Teams submit their projects)</li>
            </ul>
          </li>  
          <li>Nov 25th - Winners are notified via email and winning projects are listed for public viewing.</li>
        </ul>  
      </article>
      <article>
        <h4>What is the judging process?</h4>
        <p>Due to the large number of teams and potential hosting pitfalls that can come with, we request that 
        each team submit their project using a Koding VM. Don’t worry, you don’t need a paid account. If you 
        submit your project and your VM is turned off due to inactivity, we will turn it on for you.
        </p>
        <p>Judging will happen in three rounds:</p>
        <ol>
          <li>Round 1: All projects submitted for this round are distributed (ad-hoc) to our judges panel and 
          they will evaluate it based on API’s used, complexity of solution, adherence to the theme, team size, 
          geolocation of team, etc. Selected projects move to round 2.
          </li>
          <li>Round 2: Teams reaching this stage will have their projects evaluated on stricter versions of 
          the same criteria above and will be exposed to our entire judging staff. Each judge gets to assign 
          points (1-10) and the top 10 teams scoring the most move to the final round.
          </li>
          <Li>Round 3: Judges meet (virtually of course) for a live call to discuss and pick the final 3.
          </li>
        </ol>
        </article>
      <article class="schedule">
        <h4>How to submit your project</h4>
          <p>Send the following details to <a href="mailto:wfgh@koding.com">wfgh@koding.com</a>
            <ol>
              <li>Koding VM URL where the judges can see your project.</li>
              <li>A brief description of your project (not more than 250 words).</li>
              <li>A brief introduction to your team members (who did what).</li>
              <li>How your project addresses the theme of the hackathon.</li>
              <li>What tools did you use to collaborate.</li>
            </ol>
          <p>Your submission should have a time label less than <b>23:59 PDT, Nov 23rd 2014</b>. 
          Submissions received after the deadline will not be considered. No exceptions.
        </p>  
      </article>
      <article>
        <h4>Questions?</h4>
        <p>Send us an email at <a href="mailto:wfgh@koding.com">wfgh@koding.com</a></p>
      </article>  
      <article class='judges'>
        <h4>Judges</h4>
        <div class='clearfix'></div>
      </article>
      <!-- aside class="partners">
        <h4>Sponsors</h4>
        <img src="http://upload.wikimedia.org/wikipedia/en/archive/7/7d/20140812175330!Red_Bull.svg">
        <img src="./a/site.hackathon/images/partners/aws.png">
        <img src="./a/site.hackathon/images/partners/rackspace.jpg">
        <img src="./a/site.hackathon/images/partners/chrome.png">
      </aside -->
    </section>
    <footer>
      <a href="/">Copyright © #{(new Date).getFullYear()} Koding, Inc</a>
      <a href="/Pricing" target="_blank">Pricing</a>
      <a href="http://koding.com/Activity" target="_blank">Community</a>
      <a href="/About" target="_blank">About</a>
      <a href="/Legal" target="_blank">Legal</a>
    </footer>
    """
