CustomLinkView   = require './../core/customlinkview'
HomeRegisterForm = require './registerform'

JUDGES           =
  'Devrim Yasar' :
    imgUrl       : 'http://placepic.me/profiles/200-200-1-random'
    title        : 'Ceo & Co-founder'

  'Sinan Yasar'  :
    imgUrl       : 'http://placepic.me/profiles/200-200-2-random'
    title        : 'Ceo & Co-founder'

  'Emre Durmus'  :
    imgUrl       : 'http://placepic.me/profiles/200-200-3-random'
    title        : 'Ceo & Co-founder'

  'Burak Can'    :
    imgUrl       : 'http://placepic.me/profiles/200-200-4-random'
    title        : 'Ceo & Co-founder'

  'Can The Fason':
    imgUrl       : 'http://placepic.me/profiles/200-200-5-random'
    title        : 'Ceo & Co-founder'


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

    @addSubView (section = new KDCustomHTMLView
      tagName  : 'section'
      cssClass : 'logged-in'
    ), '.form-wrapper'

    size     = 80
    fallback = "https://koding-cdn.s3.amazonaws.com/square-avatars/default.avatar.#{size}.png"

    section.addSubView avatarBg = new KDCustomHTMLView
      cssClass   : 'avatar-background'

    avatarBg.addSubView avatar = new KDCustomHTMLView
      tagName    : 'img'
      cssClass   : 'avatar'
      attributes :
        src      : "//gravatar.com/avatar/#{hash}?size=#{size}&d=#{fallback}&r=g"

    section.addSubView label = new KDLabelView
      title : "Hey, #{firstName or nickname}!"

    label.addSubView notYou = new CustomLinkView
      title : '(not you?)'
      href  : '/Logout'
      click : (event) ->
        KD.utils.stopDOMEvent event
        document.cookie = 'clientId=null'
        location.replace '/WFGH'

    return if isApplicant

    section.addSubView button = new KDButtonView
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
            section.destroy()
            @updateGreeting()
            @updateStats()
            @createApplyWidget()
          error       : (xhr) ->
            {responseText} = xhr
            button.hideLoader()
            new KDNotificationView title : responseText


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

        @addSubView view, '.judges'


  viewAppended : ->

    super

    @updateGreeting()

    video = document.getElementById 'bgVideo'
    video.addEventListener 'loadedmetadata', ->
      this.currentTime = 8;
    , false

  updateStats: -> @$('div.counters').html @getStats()

  getStats: ->

    { cap, prize, totalApplicants, approvedApplicants } = getStats()

    return "PRIZE: $#{prize.toLocaleString()} - TOTAL SLOTS: #{cap.toLocaleString()} - APPLICATIONS: #{totalApplicants.toLocaleString()} - APPROVED APPLICANTS: #{approvedApplicants.toLocaleString()}"


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
      <h2>
        <span class='top'>JOIN THE WORLD'S FIRST</span>
        <span class='bottom'>GLOBAL HACKATHON</span>
        #WFGH
      </h2>
      <h3>Announcing the world's first global virtual hackathon IN THE BROWSER.<br> Join today to save your spot and win $10,000 in cash.</h3>
      <div class="form-wrapper clearfix"></div>
      <div class="video-wrapper">
        <video id="bgVideo" autoplay loop muted>
          <source src="./a/site.hackathon/images/intro-bg.webm" type="video/webm">
        </video>
      </div>
    </section>
    <section class="content">
      <div class="counters">#{@getStats()}</div>
      <article>
        <h4>Calling Developers of the World - All countries, All ages alike. Let's CODE!</h4>

        <p>Software is shaping our world. Yet developers are still far apart, and
        lacking a level playing field. Our browsers are now so strong to do everything
        but bringing us together to write code.
        </p>

        <p>This event wants to connect developers worldwide and help them code together.</p>


        <p>If you are looking for team members, post on the #wfgh channel
        on Koding and then jump into private chats to discuss your ideas and start
        recruiting! Your post should clearly articulate what type of skill set you are
        looking for any what type of skill set you have. e.g.: I am a php developer
        looking for a backend database team member.</p>
      </article>
      <article>
        <h4>How does it work? </h4>

        <p> Sign up above, then we will send you a short questionnaire and help you get ready.
        Nothing else is needed.</p>

      </article>
      <article>
        <h4>How do I get accepted? </h4>
        <p>Our judges decide who gets in. And they can select anyone they like.
        We can accomodate only select number of applications to keep it sane, so we will limit total applications to 5,000.
        First come first served. Apply today, and you will receive a note from us if you're accepted as soon as a judge approves.
        </p>
      </article>
      <article>
        <h4> How do I qualify? </h4>
        <p>
        <ul>
        <li>You are a developer, you have good looking Github/Stackoverflow profile page.</li>
        <li>You're a designer, you have a good looking dribbble or behance profile.</li>
        <li>Linkedin work experience is also acceptable. </li>
        <li>If you are not a developer or a designer, you should apply and let a developer and designer vouch for you.</li>
        </ul>
        </p>
      </article>
      <article>
        <h4>Yes, you can code alone, if that's your style.</h4>

        <p>However, we will favor groups, in the end, the point is to code together, most importantly
        with people that from other countries. In your application form tell us about your skills,
        and what kind of people you want to pair up with, we will select some developers and send you
        their github links, if you like them - we will organize a chat room for you to get ready.
         </p>
      </article>
      <article>
        <h4>Already have a group?</h4>

        <p>Awesome. Now it's time to pick an awesome project.</p>
      </article>
      <article>
        <h4>Ideas?</h4>

        <p> We will provide a list of ideas that are endorsed by our sponsors.
        If you pick one of those ideas or something similar, with the approval of the sponsors
        you will get to win their rewards. For example, if you choose to hack on Firebase API,
        and you win the competition, you receive the winner prize plus Firebase special prizes.</p>

        <p>Our goal is to ensure that all teams have a level playing field
        therefore it is imperative that all code, design, assets, etc must be
        created during the duration of the event. No exceptions. You can brainstorm
        ideas prior to the event however any assets or code used as part of your
        submission must have been created during the event. The only exception
        to this rule is the usage of publicly available material.
        This includes: code snippets, images, open source libraries, etc. 3rd
        party services like APIs, open source projects, open source libraries
        and frameworks are all all allowed.You get the picture. Play fair!</p>

        <p class="note">Note: If your team qualifies for a prize, you are automatically
        subject to a code and asset review to ensure that the above rule has been
        adhered to.</p>
      </article>
      <article>
        <h4>Ownership</h4>
        <p>You will retain full ownership and rights to your creation.<br>
        Be super awesome and have fun!<br>
        Get creative and have a great time. Meet new people, make new friends and problem solve with them.</p>
      </article>
      <article class="schedule">
        <h4>Schedule</h4>

        <ul>
          <li><strong>Now</strong> - Registration open</li>
          <li><strong>Nov 20th</strong> - Applications are closed. Last notifications are sent to teams/individuals who were accepted into the hackathon</li>
          <li><strong>Nov 26th</strong> - <strong>Day 1</strong>
            <ul>
              <li>0900 PDT  Announcement of topics on #WFGH</li>
              <li>0901 PDT  Let the hacking begin!</li>
            </ul>
          </li>
          <li><strong>Nov 27th</strong> - <strong>Day 2</strong>
            <ul>
              <li>0000 – 2200 PDT Hacking continues</li>
              <li>2200 – 2230 PDT Teams submit their projects</li>
            </ul>
          </li>
          <li><strong>Nov 28th</strong> - Winners are notified via email and winning projects are listed</li>
        </ul>
      </article>
      <article>
        <h4>Prizes</h4>

        <ol>
          <li>$10,000 cash prize from Koding, split amongst 1 to 3 teams (100%, 70%-30%, 50%-30%-20%)</li>
          <li>The top prize winners will be offered to have interviews with investors</li>
          <li>Sponsors will offer prizes to the winner and/or to the teams that they selected.</li>
          <li>$10,000 Amazon AWS Credit</li>
          <li>$2,000/month in free Rackspace cloud for 12 months.</li>
          <li>$1,000/month in free Digital Ocean for 12 months.</li>
        </ol>
      </article>

      <article class="judges clearfix">
        <h4>Judges</h4>
      </article>
      <aside class="partners">
        <img src="./a/site.hackathon/images/partners/atom.jpg">
        <img src="./a/site.hackathon/images/partners/atom.jpg">
        <img src="./a/site.hackathon/images/partners/atom.jpg">
        <img src="./a/site.hackathon/images/partners/atom.jpg">
        <img src="./a/site.hackathon/images/partners/atom.jpg">
      </aside>
    </section>
    <footer>
      <a href="/">Copyright © #{(new Date).getFullYear()} Koding, Inc</a>
      <a href="/Pricing" target="_blank">Pricing</a>
      <a href="http://koding.com/Activity" target="_blank">Community</a>
      <a href="/About" target="_blank">About</a>
      <a href="/tos.html" target="_blank">Legal</a>
    </footer>
    """
