class EducationView extends KDView

  JView.mixin @prototype

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

    @testimonials = new TestimonialsView

    @footer = new FooterView

    {appManager} = KD.singletons
    appManager.on 'AppIsBeingShown', (app) =>

      return unless app.getView().getId() is @getId()

      video = @$('video')[0]
      video.play()

  click:(event)->

    if $(event.target).is 'video'
      video = @$('video')[0]
      if KD.utils.isFullscreen()
        KD.utils.exitFullscreen()
      else
        KD.utils.enterFullscreen video


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
            <header><i></i><i></i><i></i>https://koding.com/Terminal</header>
            <video autoplay loop>
              <source src='https://koding-cdn.s3.amazonaws.com/movies/terminal.webm'>
              <source src='https://koding-cdn.s3.amazonaws.com/movies/terminal.mp4'>
            </video>
          </figure>
          <figure class="second">
            <img src="/a/images/ss-terminal.jpg" alt="Activity">
          </figure>
          <figure class="third">
            <img src="/a/images/ss-teamwork.jpg" alt="Terminal">
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
              what needs to get done.
            </p>
          </article>
          <article class="feature">
            <i class="team-small icon"></i>
            <h5>Collaborative</h5>
            <p>
              Invite anyone to your private session to collaborate on your
              current project. Help anyone, get help from your peers with a
              click, in realtime.
            </p>
          </article>
          <article class="feature">
            <i class="box-open icon"></i>
            <h5>Dedicated VM’s</h5>
            <p>
              Preset environments for every single lecture allows your students
              to avoid tedious setup and configuration; so they can spend more
              time learning things!
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

      {{> @testimonials}}

      <section class='check-out'>
        <div class='inner-container'>
          <h3><a href='/Pricing'>Check out our pricing</a> and get started with Koding right away!</h3>
        </div>
      </section>
      {{> @footer}}
    """


