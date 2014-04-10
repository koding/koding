class EducationView extends KDView

  constructor:->
    super

    @videoButton = new KDButtonView
      title       : "Watch video"
      style       : "solid thin medium light-gray"

    @signUpButton = new KDButtonView
      title       : "Signup"
      style       : "solid medium light-gray"
      callback    : ->
        KD.singleton("router").handleRoute "/Register"

    @LoginButton = new KDButtonView
      title       : "Login"
      style       : "solid small light-gray"
      callback    : ->
        KD.singleton("router").handleRoute "/Login"

  viewAppended: JView::viewAppended

  pistachio : ->
    """
      <section class="introduction">
        <div class="inner-container clearfix">
          <nav>
            <a href="#">Business</a>
            <a href="#">Education</a>
            <a href="#">Pricing</a>
            <a href="#">About</a>
            <a href="#">Contact</a>
            {{> @LoginButton}}
          </nav>
          <article>
            <h2>Social development environment</h2>
            <p>
              Aliquam eget turpis venenatis, vestibulum mauris ut, viverra nisl. Curabitur in ultrices arcu.<br> Nulla varius mi nec massa aliquam, sit amet gravida libero tempor.
            </p>
            {{> @signUpButton}}
            <span class="seperator">&</span>
            {{> @videoButton}}
          </article>
        </div>
      </section>

      <section class="screenshots">
        <div></div>
      </section>

      <section class="features">
        <div class="inner-container clearfix">
          <h3 class="general-title">How does this work</h3>
          <article class="feature">
            <h5>
              <i class="cloud"></i>
              Private groups & secure access to code
            </h5>
            <p>
              Aliquam eget turpis venenatis, vestibulum mauris ut,
              viverra nisl. Curabitur in ultrices arcu.
              Nulla varius mi nec massa aliquam, sit amet gravida libero tempor.
            </p>
          </article>
          <article class="feature">
            <h5>
              <i class="security"></i>
              Private groups & secure access to code
            </h5>
            <p>
              Aliquam eget turpis venenatis, vestibulum mauris ut,
              viverra nisl. Curabitur in ultrices arcu.
              Nulla varius mi nec massa aliquam, sit amet gravida libero tempor.
            </p>
          </article>
          <article class="feature">
            <h5>
              <i class="security"></i>
              Private groups & secure access to code
            </h5>
            <p>
              Aliquam eget turpis venenatis, vestibulum mauris ut,
              viverra nisl. Curabitur in ultrices arcu.
              Nulla varius mi nec massa aliquam, sit amet gravida libero tempor.
            </p>
          </article>
          <article class="feature">
            <h5>
              <i class="content"></i>
              Private groups & secure access to code
            </h5>
            <p>
              Aliquam eget turpis venenatis, vestibulum mauris ut,
              viverra nisl. Curabitur in ultrices arcu.
              Nulla varius mi nec massa aliquam, sit amet gravida libero tempor.
            </p>
          </article>
          <article class="feature">
            <h5>
              <i class="remote"></i>
              Private groups & secure access to code
            </h5>
            <p>
              Aliquam eget turpis venenatis, vestibulum mauris ut,
              viverra nisl. Curabitur in ultrices arcu.
              Nulla varius mi nec massa aliquam, sit amet gravida libero tempor.
            </p>
          </article>
          <article class="feature">
            <h5>
              <i class="cloud"></i>
              Private groups & secure access to code
            </h5>
            <p>
              Aliquam eget turpis venenatis, vestibulum mauris ut,
              viverra nisl. Curabitur in ultrices arcu.
              Nulla varius mi nec massa aliquam, sit amet gravida libero tempor.
            </p>
          </article>
        </div>
      </section>

      <section class="testimonials">
        <div class="inner-container">
          <h3 class="general-title">What did they say</h3>
          <article>
            <i class="avatar"></i>
            <p>Aliquam eget turpis venenatis, vestibulum mauris ut, viverra nisl. Curabitur in ultrices arcu. Nulla varius mi nec massa aliquam, sit amet gravida libero tempor.</p>
          </article>
        </div>
        <div class="inner-container">
          <article>
            <i class="avatar"></i>
            <p>Aliquam eget turpis venenatis, vestibulum mauris ut, viverra nisl. Curabitur in ultrices arcu. Nulla varius mi nec massa aliquam, sit amet gravida libero tempor.</p>
          </article>
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


