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

  constructor: (options = {}, data)->
    super options, data

    @setPartial @partial()
    @createJudges()
    @createJoinForm()


  createJoinForm : ->
    {router} = KD.singletons

    @signUpForm = new HomeRegisterForm
      cssClass    : 'login-form register no-anim'
      buttonTitle : 'SIGN UP'
      callback    : (formData) =>
        router.requireApp 'Login', (controller) =>
          if @signUpForm.gravatarInfoFetched
            controller.getView().showExtraInformation formData, @signUpForm

          else
            @signUpForm.once 'gravatarInfoFetched', (data) =>
              formData.gravatar = data
              controller.getView().showExtraInformation formData, @signUpForm

    @addSubView @signUpForm, '.form-wrapper'


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

    video = document.getElementById 'bgVideo'
    video.addEventListener 'loadedmetadata', ->
      this.currentTime = 8;
    , false

  partial: ->

    """
    <section class="introduction">
      <h2>
        <span class='top'>JOIN THE WORLD'S FIRST</span>
        <span class='bottom'>GLOBAL HACKATHON</span>
        #WFGH
      </h2>
      <h3>But how can we get developers from all over the world to participate? <br>
      Announcing the world's first global virtual hackathon.</h3>
      <div class="form-wrapper clearfix"></div>
      <div class="video-wrapper">
        <video id="bgVideo" autoplay loop muted>
          <source src="./a/site.hackathon/images/intro-bg.webm" type="video/webm">
        </video>
      </div>
    </section>
    <section class="content">
      <div class="counters">
        PRIZE: $10,000 - TOTAL SLOTS: 5,000 - APPLICATIONS: 54,345 - APPROVED APPLICANTS: 2345
      </div>
      <article>
        <h4>Team Size</h4>

        <p>Teams can be anywhere from one to four members. All members have to
        be contributing members, i.e.: they should either be a developer on
        the team or a designer.</p>

        <p>If you are looking for team members, post on the #kode-a-thon channel
        on Koding and then jump into private chats to discuss your ideas and start
        recruiting! Your post should clearly articulate what type of skill set you are
        looking for any what type of skill set you have. e.g.: I am a php developer
        looking for a backend database team member.</p>
      </article>
      <article>
        <h4>The “Creation” process</h4>

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
          <li><strong>Nov 20th</strong> - Notification sent to teams/individuals who were accepted into the hackathon</li>
          <li><strong>Nov 25th</strong> - <strong>Day 1</strong>
            <ul>
              <li>0900 PDT  Announcement of topics on #kode-a-thon</li>
              <li>0901 PDT  Let the hacking begin!</li>
            </ul>
          </li>
          <li><strong>Nov 26th</strong> - <strong>Day 2</strong>
            <ul>
              <li>0000 – 2200 PDT Hacking continues</li>
              <li>2200 – 2230 PDT Teams submit their projects</li>
            </ul>
          </li>
          <li><strong>Nov 28th</strong> - Winners are notified via email and winning projects are listed</li>
        </ul>
      </article>
      <article>
        <h4>Ownership</h4>

        <ol>
          <li>$100,000 investment from the LAUNCH Fund (split amongst 1 to 5 teams), or 10% cash</li>
          <li>The top prize winners will also be offered to @jason’s AngelList Syndicate – currently valued at ~ $1M</li>
          <li>Jason Calacanis will join the board of the company for the first year.</li>
          <li>Guaranteed spot on stage at the LAUNCH Festival 2015</li>
          <li>$25,000 Investment Grand Prize by Barracuda (1 winner)</li>
          <li>$10,000 in Heroku Credit (expires in 1 year, 1 winner)</li>
          <li>$2,000/month in free Rackspace cloud for 12 months.</li>
          <li>Draper University will offer a full scholarship to the DU Entrepreneurial Online Program to EACH team member of the top two winning teams.</li>
        </ol>
      </article>
      <article>
        <h4>Expedia</h4>

        <ul>
          <li>$10,000 of Expedia travel credit to book hotels and flights on Expedia.com split into five prizes as follows:</li>
            <ul>
              <li>$5,000 for 1st,</li>
              <li>$2,000 for 2nd and</li>
              <li>$1,000 each for 3rd, 4th and 5th.</li>
            </ul>
          </li>
          <li>Learn more at our 7:30PM Friday workshop. <a href="#">Get your Expedia API key now!</a></li>
        </ul>
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
      © 2014 Koding, Inc.
      <a href="#">Terms</a>
      <a href="#">Privacy</a>
      <a href="#">Security</a>
      <a href="#">Contact</a>
    </footer>
    """