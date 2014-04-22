class EducationView extends KDView

  constructor:->
    super

    {router} = KD.singletons

    @pricingButton = new KDButtonView
      title       : "See Pricing"
      style       : "solid thin medium thin-white"
      callback    : -> router.handleRoute "/Pricing/Team"

    @signUpButton = new KDButtonView
      title       : "Sign Up Now"
      style       : "solid medium green"
      callback    : -> router.handleRoute "/Register"

    @footer = new FooterView


  viewAppended: JView::viewAppended

  pistachio : ->
    """
      <section class="introduction">
        <div class="inner-container clearfix">
          <article>
            <h2>Koding for the classroom</h2>
            <p>
              Connects students and teachers together with everything already set up
            </p>
            {{> @signUpButton}}
            {{> @pricingButton}}
          </article>
        </div>
      </section>

      <section class="screenshots">
        <div class="inner-container">
          <figure class="first">
            <img src="/a/images/ss-activity.jpg" alt="Activity">
          </figure>
          <figure class="second">
            <img src="/a/images/ss-teamwork.jpg" alt="Teamwork">
          </figure>
          <figure class="third">
            <img src="/a/images/ss-terminal.jpg" alt="Terminal">
          </figure>
        </div>
      </section>

      <section class="features">
        <div class="inner-container clearfix">
          <article class="feature">
            <i class="bubble icon"></i>
            <h5>Instant feedback on anything</h5>
            <p>
              Never miss a thing. Who is working on what, who needs help,
              what needs to get done,
            </p>
          </article>
          <article class="feature">
            <i class="team-small icon"></i>
            <h5>Collaborative</h5>
            <p>
              Invite anyone to your private session to collaborate on your
              current project. Help anyone, get help from your peer with a
              click, in realtime.
            </p>
          </article>
          <article class="feature">
            <i class="box-open icon"></i>
            <h5>Dedicated VM’s</h5>
            <p>
              Already set up environments for every single lecture.
              Less time setting up things from ground up, more time
              writing actual code!
            </p>
          </article>
          <article class="feature">
            <i class="browser icon"></i>
            <h5>Accesible</h5>
            <p>
              Remote is the new local. Connect different groups of students
              together. Solve real problems, realtime.
            </p>
          </article>
        </div>
      </section>

      <section class="testimonials">
        <div class="inner-container clearfix">
          <h3 class="general-title">What did they say</h3>
          <h4 class="general-subtitle">People love Koding for a reason. Guess what that reason is?</h4>

          <article>
            <p>It just f***in works! And therefore I love it like I ove my mom.</p>
            <span class="name">JASON FRIEDMANN</span>
          </article>

          <article>
            <p>It just f***in works! And therefore I love it like I ove my mom.</p>
            <span class="name">JASON FRIEDMANN</span>
          </article>

          <article>
            <p>It just f***in works! And therefore I love it like I ove my mom.</p>
            <span class="name">JASON FRIEDMANN</span>
          </article>

          <article>
            <p>It just f***in works! And therefore I love it like I ove my mom.</p>
            <span class="name">JASON FRIEDMANN</span>
          </article>
        </div>
      </section>

      <section class='check-out'>
        <h3><a href='/Pricing'>Check out our pricing</a> and get started with Koding right away!</h3>
      </section>
      {{> @footer}}
    """


