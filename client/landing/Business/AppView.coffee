class BusinessView extends KDView

  constructor:->
    super

    @signUpButton = new KDButtonView
      title       : "SIGN UP NOW"
      style       : "solid medium green"

    @learnMoreButton = new KDButtonView
      title       : "LEARN MORE"
      style       : "solid medium white thin"

    @signInButton = new KDButtonView
      title       : "SIGN IN"
      style       : "solid medium white thin"

    @contentSlider = window.a = new BusinessSliderView
      contents     :
        first      :
          title    : "Control your dev environment like a boss"
          subTitle : "Keep control your team in a intranet-like space with ready to roll VMs, in the cloud!"
          imgUrl   : "/a/images/biz-slider/1.jpg"
        second     :
          title    : "Lorem ipsum dolor sit amet, consectetur adipiscing elit"
          subTitle : "Keep control your team in a intranet-like space with ready to roll VMs, in the cloud!"
          imgUrl   : "/a/images/biz-slider/1.jpg"
        third      :
          title    : "Control your dev environment like a boss"
          subTitle : "Keep control your team in a intranet-like space with ready to roll VMs, in the cloud!"
          imgUrl   : "/a/images/biz-slider/1.jpg"
        fourth     :
          title    : "Lorem ipsum dolor sit amet, consectetur adipiscing elit"
          subTitle : "Keep control your team in a intranet-like space with ready to roll VMs, in the cloud!"
          imgUrl   : "/a/images/biz-slider/1.jpg"

    @planSelectionWrapper = new KDView

    appManager = KD.singleton "appManager"
    appManager.require "Pricing", (app) =>

      @planSelectionView = new TeamPlan
        pistachio :
          """
            <div class="big box with-arrow">
              {{> @resourcePackSlider}}
              {{> @userSlider}}
            </div>
            <div class="small box">
              {{> @summary}}
            </div>
          """

      @planSelectionWrapper.addSubView @planSelectionView


  viewAppended: JView::viewAppended

  pistachio : ->
    """
      <section class="introduction">
        <div class="inner-container clearfix">
          <nav>
            <a href="#">ABOUT</a>
            <a href="#">PRICING</a>
            <a href="#">BLOG</a>
            {{> @signInButton}}
          </nav>
          <article>
            <h2>Koding for Business</h2>
            <p>
              Ruby. Python. PHP. doesn’t matter. No setup,<br>
              just working VMs ready to roll. Watch a <em>quick video</em><br>
              to get the idea.
            </p>
            {{> @signUpButton}}
            {{> @learnMoreButton}}
          </article>
          <figure></figure>
        </div>
      </section>

      <section class="features">
        <div class="inner-container clearfix">
          <div class="appstore feature">
            <h3>APPSTORE</h3>
            <p>Koding apps to speed up your noob processes<p>
          </div>
          <div class="teamwork feature">
            <h3>TEAMWORK</h3>
            <p>Collaborative development environment for your pleasure<p>
          </div>
          <div class="social feature">
            <h3>SOCIAL</h3>
            <p>Ask the masters of code, help out the poor noob.<p>
          </div>
        </div>
      </section>

      <section class="content-slider">
        <div class="inner-container">
          {{> @contentSlider}}
        </div>
      </section>

      <section class="pricing">
        <div class="inner-container clearfix">
          <h3 class="general-title">Single developer or a team, doesn’t really matter</h3>
          <h4 class="general-subtitle">Super-scalable pricing for your scalable projects</h4>

          {{> @planSelectionWrapper}}

        </div>
      </section>

      <section class="quotes">
        <div class="inner-container clearfix">
          <h3 class="general-title">Hearing good things about your product is awesome</h3>
          <h4 class="general-subtitle">Here are some awesome people, sayin awesome things about us</h4>

          <blockquote class="clearfix">
            <p>
              Awesome product, awesome team,
              awesome food.
              What can I say,
              I love this company
            </p>
            <div class="person">
              <img src="http://d13yacurqjgara.cloudfront.net/users/45397/avatars/small/mrd.png?1390348178">
              <span class="name">Emre Durmus</span>
              <span class="bio">Designer @ Koding</span>
            <div>
          </blockquote>

          <blockquote class="clearfix">
            <p>
              Awesome product, awesome team,
              awesome food.
              What can I say,
              I love this company
            </p>
            <div class="person">
              <img src="http://d13yacurqjgara.cloudfront.net/users/45397/avatars/small/mrd.png?1390348178">
              <span class="name">Emre Durmus</span>
              <span class="bio">Designer @ Koding</span>
            <div>
          </blockquote>

        </div>
      </section>

      <section class="customers">
        <div class="inner-container">
          <img src="/a/images/stanford-logo.png" alt="Stanford University">
          <img src="/a/images/mit-logo.png" alt="MIT">
          <img src="/a/images/nasa-logo.png" alt="NASA">
          <img src="/a/images/tesla-logo.png" alt="Tesla Motors">
        </div>
      </section>

      <footer>
        <div class="inner-container">
          <address>
            2014 © Koding, Inc. 358 Brannan Street, San Francisco, CA, 94107
          </address>
          <nav>
            <a href="#">ACTIVITY</a>
            <a href="#">ABOUT</a>
            <a href="#">CONTACT</a>
            <a href="#">UNIVERSITY</a>
            <a href="#">JOBS</a>
            <a href="#">BLOG</a>
            <a href="#">STATUS</a>
          </nav>
        </div>
      </footer>
    """


