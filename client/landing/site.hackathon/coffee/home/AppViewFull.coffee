CustomLinkView   = require './../core/customlinkview'
HomeRegisterForm = require './registerform'

TWEET_TEXT       = 'I\'ve applied for the world\'s first global virtual #hackathon by @koding. Join my team!'
SHARE_URL        = 'https://koding.com/Hackathon2014'

VIDEO_URL        = 'https://koding-cdn.s3.amazonaws.com/campaign/hackathon/intro-bg.webm'
VIDEO_URL_MP4    = 'https://koding-cdn.s3.amazonaws.com/campaign/hackathon/intro-bg.mp4'
VIDEO_URL_OGG    = 'https://koding-cdn.s3.amazonaws.com/campaign/hackathon/intro-bg.ogv'

DAYS             = ['SUNDAY','MONDAY','TUESDAY','WEDNESDAY','THURSDAY','FRIDAY','SATURDAY']
MONTHS           = ['JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE', 'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER']

{
  judges   : JUDGES
  partners : PARTNERS
} = KD.campaignStats.campaign

module.exports = class HomeViewFull extends KDView

  getStats = ->

    KD.campaignStats ?=
      campaign           :
        cap              : 50000
        prize            : 10000
      totalApplicants    : 34512
      approvedApplicants : 12521
      isApplicant        : no
      isApproved         : no
      isWinner           : no

  constructor: (options = {}, data)->

    options.bind = 'mousemove'

    super options, data

    @logosBeingDragged = no

    @setPartial @partial()
    @createPartners()
    @createJudges()
    @createJoinForm()


  createJoinForm : ->
    {router} = KD.singletons


    if KD.isLoggedIn()
    then @createApplyWidget()
    else @$('.form-wrapper').hide()

    #   @signUpForm = new HomeRegisterForm
    #     cssClass    : 'login-form register no-anim'
    #     buttonTitle : 'LET\'S DO THIS'
    #     callback    : (formData) =>
    #       router.requireApp 'Login', (controller) =>
    #         controller.getView().showExtraInformation formData, @signUpForm

    #   @addSubView @signUpForm, '.form-wrapper'


  createApplyWidget: ->

    {firstName, lastName, nickname, hash} = KD.whoami().profile
    {isApplicant, isApproved, isWinner} = getStats()

    if KD.isLoggedIn() and isApplicant
      @setClass 'applied'
    else if KD.isLoggedIn()
      @setClass 'about-to-apply'

    return @createShareButtons()  if isApplicant

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


    # @section.addSubView @button = new KDButtonView
    # @section.addSubView @button = new KDButtonView
    #   cssClass : 'apply-button solid green medium'
    #   title    : 'APPLY NOW'
    #   loader   : yes
    #   callback : @bound 'apply'


  apply: ->

    $.ajax
      url         : '/Hackathon2014/Apply'
      type        : 'POST'
      xhrFields   : withCredentials : yes
      success     : (stats) =>
        # @button.hideLoader()
        KD.campaignStats = stats
        @updateWidget()
        KD.singletons.router.handleRoute '/Hackathon2014'
      error       : (xhr) =>
        {responseText} = xhr
        # @button?.hideLoader()
        new KDNotificationView title : responseText
        KD.singletons.router.handleRoute '/Hackathon2014'


  updateWidget : ->

    @section.destroy()
    @updateStats()
    @createApplyWidget()


  createShareButtons: ->

    { isApplicant, isApproved, isWinner } = getStats()


    if isApplicant and not isApproved
      greeting = """
        <strong>THANK YOU!</strong>
        We have received your application. You\'ll shortly receive an email with more details!</br>
        Share now to increase your chances to get approved!
        """

    if isApplicant and isApproved
      greeting   = '<strong>CONGRATULATIONS!</strong>you are in!'
      TWEET_TEXT = 'Awesome! I\'ve been accepted into @koding\'s global virtual #hackathon.'


    if isApplicant and isWinner
      greeting = '<strong>WOHOOOO!</strong>You are the WINNER!'
      TWEET_TEXT = 'Woohoooo! I won @koding\'s global virtual #hackathon.'

    @$('.form-wrapper').append "<p>#{greeting}</p>"
    @$('.form-wrapper').append "<div class=\"addthis_sharing_toolbox\" data-title=\"#{TWEET_TEXT}\" data-url=\"#{SHARE_URL}\"></div>"

    repeater = KD.utils.repeat 200, ->
      if addthis?.layers?.refresh
        addthis.layers.refresh()
        KD.singletons.mainView.header.nav.addThis.destroy()
        KD.utils.killRepeat repeater


  createJudges : ->

    for name, content of JUDGES
      view = new KDCustomHTMLView
        cssClass    : 'judge'

      view.addSubView new KDCustomHTMLView
        tagName     : 'figure'
        attributes  :
          style     : "background-image:url(#{content.imgUrl});"

      view.addSubView new CustomLinkView
        cssClass    : 'info'
        title       : name
        href        : content.linkedIn
        target      : '_blank'

      view.addSubView new KDCustomHTMLView
        cssClass    : 'details'
        partial     : "<span>#{content.title}</span><cite>#{content.company}</cite>"

      @addSubView view, '.judges > div'


  createPartners: ->

    header = null

    for name, {img, url, prize} of PARTNERS

      unless header
        header = new KDCustomHTMLView
          tagName : 'h4'
          partial : 'Awesome Prizes'
        @addSubView header, 'aside.partners'

      image = new KDCustomHTMLView
        tagName    : 'a'
        attributes :
          href     : url
          target   : '_blank'
        partial    : "<img src='#{img}' alt='#{name}' \>"

      @addSubView image, 'aside.partners'


  viewAppended : ->

    super

    @logos = new KDCustomHTMLView
      cssClass  : 'logos'
      tagName   : 'figure'
      bind      : 'mousemove mouseleave mouseenter'
      partial    : """
        <i class="odesk"></i>
        <i class="kissmetrics"></i>
        <i class="accel"></i>
        <i class="udemy"></i>
        <i class="aws"></i>
        <i class="tutum"></i>
        <i class="code"></i>
        <i class="facebook"></i>
        <i class="atlassian"></i>
        <i class="iron"></i>
        <i class="turkcell"></i>
        <i class="digitalocean"></i>
        <i class="deviantart"></i>
        <i class="baincapital"></i>
        <i class="eniac"></i>
        """

    logosTitle = new KDCustomHTMLView
      tagName  : 'span'
      cssClass : 'logos-title'
      partial  : 'with some amazing judges from:'
    @addSubView logosTitle, 'section.introduction'

    @addSubView @logos, 'section.introduction'

    video = document.getElementById 'bgVideo'
    if window.innerWidth < 680
      video.parentNode.removeChild video
    else
      video.addEventListener 'loadedmetadata', ->
        @currentTime = 8
        @playbackRate = .7
        KD.utils.wait 3000, -> video.classList.add 'in'
      , no


  mouseMove: (event) ->

    yPos   = event.clientY + window.scrollY
    height = @$('section.introduction').outerHeight()

    if height - 250 < yPos < height + 50
    then @mouseEnter()
    else return @mouseLeave()

    ww        = window.innerWidth
    width     = @logos.getWidth()
    slideable = width - ww
    margin    = -(width / 2)
    percent   = event.clientX / ww
    slide     = slideable * percent
    newMargin = (margin + (slideable / 2)) - slide

    @logos.setCss 'margin-left', "#{newMargin}px"


  mouseLeave: ->

    return  unless @logosBeingDragged

    @logosBeingDragged = no
    @logos.unsetClass 'no-anim'
    @logos.setCss 'margin-left', '-1400px'


  mouseEnter: do ->
    waiting = no
    ->
      return  if waiting or @logosBeingDragged
      waiting = yes
      KD.utils.wait 300, =>
        waiting = no
        @logosBeingDragged = yes
        @logos.setClass 'no-anim'


  updateStats: -> @$('div.counters').html @getStats()


  getStats: ->

    { totalApplicants, approvedApplicants, campaign } = getStats()
    { cap, prize } = campaign

    return """
      PRIZES WORTH: <span>$#{prize.toLocaleString()}</span>
      TOTAL SLOTS: <span>#{cap.toLocaleString()}</span>
      APPLICATIONS: <span>#{totalApplicants.toLocaleString()}</span>
      APPROVED APPLICANTS: <span>#{approvedApplicants.toLocaleString()}</span>
      """

  click: (event) ->

    return  if event.target.tagName in ['INPUT', 'BUTTON']

    video    = document.getElementById 'bgVideo'
    speed    = video.playbackRate

    video.play()

    repeater = KD.utils.repeat 20, ->

      speed += .02
      video.playbackRate = speed

      if speed >= 1
        video.playbackRate = 1
        KD.utils.killRepeat repeater



  partial: ->

    campaign    = KD.campaignStats?.campaign
    { prize }   = campaign
    endDay      = campaign.endDay      or 'Nov 16, 2014, 23:59 (PST)'
    closeDay    = campaign.closeDay    or 'Nov 16th'
    announceDay = campaign.announceDay or 'Nov 18th'
    firstDay    = campaign.firstDay    or 'Nov 22th'
    secondDay   = campaign.secondDay   or 'Nov 23rd'
    emailDay    = campaign.emailDay    or 'Nov 25th'

    """
    <section class="introduction">
      <video id="bgVideo" autoplay loop muted>
        <source src="#{VIDEO_URL}" type="video/webm"; codecs=vp8,vorbis">
        <source src="#{VIDEO_URL_OGG}" type="video/ogg"; codecs=theora,vorbis">
        <source src="#{VIDEO_URL_MP4}">
      </video>
      <h3>To celebrate 500,000 developers...</h3>
      <h1>ANNOUNCING THE WORLD’S FIRST GLOBAL VIRTUAL <span>#HACKATHON</span></h1>
      <h3>Applications are now closed!</h3>
      <div class="form-wrapper clearfix #{if KD.isLoggedIn() then 'logged-in'}"></div>
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
        <p>Welcome to the World’s First Global Virtual Hackathon!</p>

        <p>This event is intended to connect developers across the globe and get them to  code
        together irrespective of their locations. You will problem solve and build with old or
        new team members and try to win!
        </p>
      </article>
      <article>
        <h4>How does it work? </h4>

        <p>First, sign up using the simple form above. Every day (up until we stop accepting
        applications on Dec 3rd, 2014 12 noon PST) between 4-5pm PST, we will send all new
        applicants a short questionnaire that will help us learn a little bit more about
        you and your team’s background. We promise to keep it short and sweet.
        </p>

        <p>Applications can come from individuals or teams of up to 5. Only one member per team
        needs to apply for the entire team to be accepted but all members need to have Koding
        accounts. Additionally, each team member needs to be a contributing team member
        (writing code or designing).
        </p>

        <p>If you are an individual who is selected and are looking for team members, post a
        message on the <a href="https://koding.com/Activity/Topic/hackathon" target=_blank>
        #hackathon channel on Koding</a>. Your post should clearly articulate what type
        of skill set you are looking for and what type of skill set you have. e.g.: <i>I am a nodeJS
        developer looking for a backend database team member.</i> Once you get a response, jump into
        private chats on Koding itself to discuss your ideas and start recruiting!
        </p>

        <p>
        Prizes (described below) are in three different categories so it does not matter if you
        are an expert, a student or a beginner at programming. Everyone can compete and win!
        </p>
      </article>
      <article>
        <h4>How do I get accepted? </h4>
        <p>We expect a lot of you to apply but to keep things sane, we will be limiting the
        final competition to <span style="color: red; font-weight: bold; text-decoration: line-through;">1000</span> 2000 teams. Our panel of judges will decide who will be part
        of the competition. Their decision will be based on factors like location, team size,
        project work on github, social presence, etc. Applications are being reviewed on a first
        come first serve basis so apply today and if approved, you will receive an email from
        us with further instructions. We will also let you know if your application is not approved.
        </p>
      </article>
      <article>
        <h4>What is the theme for the Hackathon?</h4>
        <p>
        The following themes have been selected:
        <ol>
          <li>Problems facing our planet, explained using interactive data visualization.
          (e.g. climate change, earthquakes, food/water waste, accessibility related issues, etc.)</li>
          <li>Introducing software development to a beginner (games!)</li>
          <li>No one reads the fine print (ie TOS, EULA, legal documents) anymore yet every
          site has them. Devise a creative/interactive solution.</li>
          <li>HTML5 games that are educational and learning oriented. (multiplayer preferred)</li>
          <li>Challenges associated with real time communication and translation (Star
          Trek universal translator anyone?)</li>
        </ol>
        <p>Your task is to use publicly available resources (APIs, data sets, graphics, etc.) and
        your imagination to create a project that addresses one of the themes of the event.
        </p>
      </article>
      <article>
        <h4>What are the prizes?</h4>
        <p>Total prizes over <strong>$#{prize.toLocaleString()}</strong>! Here are the details.</p>
    <p>Prizes will be awarded in three categories:</p>
    <h6>Top Hacker:</h6>
    <ol>
      <li>First prize:  <s>$5,000</s> $8,000</li>
      <li>Second prize: <s>$3,000</s> $4,000</li>
      <li>Third prize: $2,000</li>
    </ol>
    <h6>Student Hacker (High school or less):</h6>
    (Please note: Student hackers are not precluded from submitting their project for the Top Hacker
    category.)
    <ol>
      <li>First prize: $1,500</li>
      <li>Second prize: $1,000</li>
      <li>Third prize: $500</li>
    </ol>
    <h6>Apprentice Hacker:</h6>
    <ol>
      <li>First prize: $1,200</li>
      <li>Second prize: $800</li>
      <li>Third prize: $500</li>
    </ol>
      </article>
      <article class='additional-prizes'>
        <h4>Additional Prizes</h4>
        <p>These will be presented to the #1 winning team in the "Top Hacker" prize category.</p>
        <ul>
          <li>
            <figure>
              <img src='http://i.imgur.com/bLUIGvk.png' alt='Count.ly logo'/>
              <figcaption><a href='http://count.ly?utm_source=koding' target='_blank'>Count.ly</a> will award an extra <strong>$1,000</strong> to the winning team if they have a Countly account so register today!</figcaption>
            </figure>
          </li>
          <li>
            <figure>
              <img src='http://nginx.com/wp-content/themes/nginx-theme/images/logos/main_logo.png' alt='nginx logo'/>
              <figcaption><a href='http://nginx.com' target=_blank>nginx</a> is adding an additional <strong>$2,000</strong> to the overall prize money for the top winning team if the team uses their web server as part of their final project.</figcaption>
            </figure>
          </li>
          <li>
            <figure>
              <img src='./a/site.hackathon/images/partners/elance-odesk.jpg' alt='Elance-oDesk logo'/>
              <figcaption>If the winning team has an <a href='http://www.odesk.com' target='_blank'>oDesk.com</a> or <a href='http://www.elance.com' target='_blank'>Elance.com</a> account, they will receive an extra <strong>$2,500</strong>. Register today if you don't have an account with them.
        </figcaption>
            </figure>
          </li>
          <li>
            <figure>
              <figcaption>The top winning team will receive <strong>$5,000</strong> in account credit from <a href='http://www.digitalocean.com' target='_blank'>Digital Ocean</a>.</figcaption>
            </figure>
          </li>
          <li>
            <figure>
              <figcaption><a href='http://www.tutum.co' target='_blank'>Tutum</a><strong> is giving one year service</strong> to the winning team.</figcaption>
            </figure>
          </li>
          <li>
            <figure>
              <figcaption><a href='http://www.firebase.com' target='_blank'>Firebase</a> will award <strong>$5,500</strong> worth of credit to the winning team.</figcaption>
            </figure>
          </li>
         </ul>
    </article>
    <article class='additional-prizes'>
    <h4>These prizes can be won by any team</h4>
    <p><strong>Even if you don't win the top 3 spots in the "Top Hacker" prize
    category, you can still apply to win these prizes.</strong></p>
     <ul>
          <li>
            <figure>
              <img src='http://i.imgur.com/H9vYUd8.png' alt='Intuit logo'/>
              <figcaption><a href='https://developer.intuit.com/' target='_blank'>Intuit</a> will award an extra <strong>$2,500</strong> to the team that presents the best use of the QuickBooks API.</figcaption>
            </figure>
          </li>
          <li>
            <figure>
              <img src='http://i.imgur.com/bLUIGvk.png' alt='Count.ly logo'/>
              <figcaption><a href='http://count.ly?utm_source=koding' target='_blank'>Count.ly</a> will award an extra <strong>$1,000</strong> to the winning team if they have a Countly account.</figcaption>
            </figure>
          </li>
          <li>
            <figure>
              <img src='http://www.pubnub.com/static/images/structure/pubnub.png' alt='PubNub logo'/>
              <figcaption><a href='http://pubnub.com' target=_blank>PubNub</a> will award an additional <strong>$1,000</strong> to the team that makes the best use of their API.</figcaption>
            </figure>
          </li>
          <li>
            <figure>
              <figcaption><a href='https://www.3scale.net/'>3Scale</a> will offer an additional <strong>$1,500</strong> to the team that makes the best usage of any API on their site.</figcaption>
            </figure>
          </li>
          <li>
            <figure>
              <figcaption><a href='http://www.datadoghq.com' target='_blank'>DATADOG</a> will award <strong>$1,000</strong> to the team that makes the best use of their service and their API.</figcaption>
            </figure>
          </li>
          <li>
            <figure>
              <figcaption><a href='https://www.mashape.com/?utm_source=koding&utm_medium=referral&utm_campaign=kodinghackathon' target='_blank'>Mashape</a> will reward an additional <strong>$1,000</strong> to the team that uses any API on Mashape.</figcaption>
            </figure>
          </li>
          <li>
            <figure>
              <figcaption><a href='https://sprint.ly/landing/koding'>Sprintly</a> will offer <strong>$1,000</strong> to the team that 1) has a Sprintly account, 2) uses their API.</figcaption>
            </figure>
          </li>
            <li>
            <figure>
              <figcaption><a href='https://www.apitools.com/'>APITools</a> will offer <strong>$1,500</strong> to the team that uses APItools in the creation of their project.</figcaption>
            </figure>
          </li>
        </ul>
      </article>
      <article>
        <h4>What is the schedule?</h4>
        <ul>
          <li>Now - Registration open.</li>
          <li>#{closeDay}, 1200 PST - Applications are closed. Final notifications are sent to teams/individuals
          who are accepted</li>
          <li>#{firstDay} - Day 1 Let the hacking begin!</li>
          <li>#{secondDay} - Day 2 of the Hackathon
            <ul>
              <li>0000 – 2200 PST Hacking continues</li>
              <li>2330 – 2359 PST Teams submit their projects to <a href="mailto:hackathon@koding.com">hackathon@koding.com</a> (see section below on how to submit)</li>
            </ul>
          </li>
          <li>#{emailDay} - Winners are notified and winning projects are listed for public viewing.</li>
        </ul>
      </article>
      <article class='judges'>
        <h4>Judges</h4>
        <p>Because we expect a large number of applicants, we wanted to ensure that we have a good number of awesome judges to help evaluate the incoming projects. These amazing folks have agreed to become part of our event. We cannot thank them enough.</p>
        <div class='clearfix'></div>
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
      <article>
        <h4> What are the rules?</h4>
        <ol>
          <li>You (or someone from your team) must be approved by Koding and should have our acceptance email.</li>
          <li>Go to <a href="https://github.com/koding/global.hackathon/" target=_blank>this repo on GitHub</a> and
          follow the instructions presented there.</li>
          <li>All team members must have a Koding account.</li>
          <li>All project developed must be directly aligned with one of the themes of the event.</li>
          <li>Your project MUST BE a web app that is viewable on your Koding VMs web URL. Mobile
          apps are not allowed. (Don't worry if you don't have an always-on Koding VM, we will take
          care of that for you when we review your work.)</li>
        </ol>
        <p>Our goal is to ensure that all teams have a level playing field; therefore it is
        imperative that all code, design, assets, etc… must be created during the duration
        of the event. No exceptions. You can brainstorm ideas prior to the event, however
        any assets or code used as part of your submission must have been created during the event.
        The only exception to this rule is the usage of publicly available material. This includes:
        public code snippets, images, open source libraries and projects, public APIs, etc. You
        get the picture.
        </p>

        <p>We will request a review of all the code you submit as part of your hackathon project
        to ensure that it has been created during the hackathon period (Dec 6th - Dec 7th).
        Being engineers ourselves we are savvy to what can and can't be created in 48 hours. :)</p>

        <p>Play fair!</p>
      </article>
      <article>
        <h4>Who will eventually own the projects created?</h4>

        <p>You will retain full ownership and rights to your creation. Be super awesome and have fun! Get
        creative, meet new people, make new friends and problem solve with them.
        </p>
      </article>
      <article class="schedule">
        <h4>How to submit your project</h4>
        <p>Please follow the submission details that were emailed to you.</p>
      </article>
      <article class='apis'>
        <h4>Awesome API's for you to check out</h4>
        <br />
        <a href="http://developer.factual.com/">Factual</a>
        <a href="http://dev.iron.io/worker/reference/api/">Iron.io</a>
        <a href="https://developer.intuit.com/">Intuit</a>
        <a href="https://developer.spotify.com/web-api/">Spotify</a>
        <a href="http://code.google.com/apis/maps/documentation/places/">Google Places</a>
        <a href="https://developers.google.com/maps/documentation/geocoding/">Google Geocoding</a>
        <a href="https://developers.google.com/books/">Google Books</a>
        <a href="http://opensocial.org/">OpenSocial</a>
        <a href="https://cloud.google.com/prediction/docs">Google Predictions</a>
        <a href="https://delicious.com/help/api">Delicious</a>
        <a href="https://www.flickr.com/services/api/">Flickr</a>
        <a href="https://developer.yahoo.com/">Yahoo Local</a>
        <a href="https://dev.twitter.com/">Twitter</a>
        <a href="https://developers.facebook.com/">Facebook</a>
        <a href="https://developer.foursquare.com/">Foursquare</a>
        <a href="https://developers.soundcloud.com/">Soundcloud</a>
        <a href="http://www.yelp.com/developers/documentation">Yelp</a>
        <a href="http://dev.bitly.com/">Bit.ly</a>
        <a href="http://www.twilio.com/docs/api/rest">Twilio</a>
        <a href="https://developer.linkedin.com/apis">LinkedIn</a>
        <a href="https://developers.google.com/freebase/">Freebase</a>
        <a href="http://products.wolframalpha.com/api/">Wolfram Alpha</a>
        <a href="https://import.io/docs/">Import.io</a>
        <a href="http://respoke.github.io/koding-hackathon/">Respoke</a>
        <a href="https://www.kimonolabs.com/">Kimono</a>
        <a href="https://api.imgur.com//">Imgur</a>
        <p>
        ...to name a few. And any mention of APIs would be incomplete without a hat tip
        to <a href="http://www.programmableweb.com/">Programmable Web</a>
        </p>
      </article>
      <article>
        <h4>Questions?</h4>
        <p>Send us an email at <a href="mailto:hackathon@koding.com">hackathon@koding.com</a></p>
        <p>(We would like to thank NASA for the awesome video.)</p>
      </article>
      <div class="sidebar">
        <aside class="partners"></aside>
        <div class="twitter-wrapper">
          <h4>Tweets</h4>
          <a class="twitter-timeline" href="https://twitter.com/search?q=%40koding+%23hackathon" data-widget-id="527247467851423745" data-chrome="nofooter noheader transparent">Tweets about "@koding #hackathon"</a>
          <script>!function(d,s,id){var js,fjs=d.getElementsByTagName(s)[0],p=/^http:/.test(d.location)?'http':'https';if(!d.getElementById(id)){js=d.createElement(s);js.id=id;js.src=p+"://platform.twitter.com/widgets.js";fjs.parentNode.insertBefore(js,fjs);}}(document,"script","twitter-wjs");</script>
        </div>
      </div>
    </section>
    <footer>
      <a href="/">Copyright © #{(new Date).getFullYear()} Koding, Inc</a>
      <a href="/Pricing" target="_blank">Pricing</a>
      <a href="http://koding.com/Activity" target="_blank">Community</a>
      <a href="/About" target="_blank">About</a>
      <a href="/Legal" target="_blank">Legal</a>
    </footer>
    """
