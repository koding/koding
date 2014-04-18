class EducationView extends KDView

  constructor:->
    super

    @pricingButton = new KDButtonView
      title       : "See Pricing"
      style       : "solid thin medium thin-white"

    @signUpButton = new KDButtonView
      title       : "Sign Up Now"
      style       : "solid medium green"
      callback    : ->
        KD.singleton("router").handleRoute "/Register"

    @LoginButton = new KDButtonView
      title       : "Sign in"
      style       : "solid medium thin-white"
      callback    : ->
        KD.singleton("router").handleRoute "/Login"

  viewAppended: JView::viewAppended

  pistachio : ->
    """
      <section class="introduction">
        <div class="inner-container clearfix">
          <nav>
            <a href="/Education">EDUCATION</a>
            <a href="/Business">BUSINESS</a>
            <a href="/About">ABOUT</a>
            <a href="/Pricing">PRICING</a>
            <a href="http://blog.koding.com" target="_blank">BLOG</a>
            {{> @LoginButton}}
          </nav>
          <article>
            <h2>Koding for Busy People</h2>
            <p>
              Aliquam eget turpis venenatis, vestibulum mauris ut, viverra nisl. Curabitur in ultrices arcu.<br> Nulla varius mi nec massa aliquam, sit amet gravida libero tempor.
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
          <h3 class="general-title">Features from the future, for biz people</h3>
          <h4 class="general-subtitle">Educational pricing for your school, you are the future!</h4>
          <article class="feature">
            <i class="cloud icon"></i>
            <h5>Private groups & secure access to code</h5>
            <p>
              Aliquam eget turpis venenatis, vestibulum mauris ut,
              viverra nisl. Curabitur in ultrices arcu.
              Nulla varius mi nec massa aliquam, sit amet gravida libero tempor.
            </p>
          </article>
          <article class="feature">
            <i class="cloud icon"></i>
            <h5>Private groups & secure access to code</h5>
            <p>
              Aliquam eget turpis venenatis, vestibulum mauris ut,
              viverra nisl. Curabitur in ultrices arcu.
              Nulla varius mi nec massa aliquam, sit amet gravida libero tempor.
            </p>
          </article>
          <article class="feature">
            <i class="cloud icon"></i>
            <h5>Private groups & secure access to code</h5>
            <p>
              Aliquam eget turpis venenatis, vestibulum mauris ut,
              viverra nisl. Curabitur in ultrices arcu.
              Nulla varius mi nec massa aliquam, sit amet gravida libero tempor.
            </p>
          </article>
          <article class="feature">
            <i class="cloud icon"></i>
            <h5>Private groups & secure access to code</h5>
            <p>
              Aliquam eget turpis venenatis, vestibulum mauris ut,
              viverra nisl. Curabitur in ultrices arcu.
              Nulla varius mi nec massa aliquam, sit amet gravida libero tempor.
            </p>
          </article>
          <article class="feature">
            <i class="cloud icon"></i>
            <h5>Private groups & secure access to code</h5>
            <p>
              Aliquam eget turpis venenatis, vestibulum mauris ut,
              viverra nisl. Curabitur in ultrices arcu.
              Nulla varius mi nec massa aliquam, sit amet gravida libero tempor.
            </p>
          </article>
          <article class="feature">
            <i class="cloud icon"></i>
            <h5>Private groups & secure access to code</h5>
            <p>
              Aliquam eget turpis venenatis, vestibulum mauris ut,
              viverra nisl. Curabitur in ultrices arcu.
              Nulla varius mi nec massa aliquam, sit amet gravida libero tempor.
            </p>
          </article>
        </div>
      </section>

      <section class="testimonials">
        <div class="inner-container clearfix">
          <h3 class="general-title">What did they say</h3>
          <h4 class="general-subtitle">Pople love Koding for a reason. Guess what that reason is?v</h4>

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

      <footer>
        <div class="inner-container clearfix">
          <article class="footer-block about-koding">
            <h5>ABOUT KODING</h5>
            <p>Koding is a developer community and cloud development environment where developers come together and code in the browser – with a real development server to run their code. Developers can work, collaborate, write and run apps without jumping</p>
            <a href="#">More about Koding</a>
          </article>

          <nav class="footer-block">
            <h5>COMPANY</h5>
            <a href="#">ABOUT KODING</a>
            <a href="#">KODING UNIVERSITY</a>
            <a href="#">CONTACT US</a>
            <a href="#">TERMS AND CONDITIONS</a>
            <a href="#">PRIVACY POLICY</a>
            <a href="#">SHOP</a>
          </nav>

          <nav class="footer-block">
            <h5>COMMUNITY</h5>
            <a href="#">KODING BLOG</a>
            <a href="#">MEETUPS</a>
            <a href="#">NEWSLETTER</a>
            <a href="#">TESTIMONALS</a>
            <a href="#">BRAND GUIDELINES</a>
          </nav>

          <nav class="footer-block blog">
            <h5>KODING BLOG</h5>
            <a href="#">Koding introduces 250TB week</a>
            <a href="#">Just opensourced KDFramework</a>
            <a href="#">Hired Jony Ive for office management</a>
            <a href="#">Cried all day, funny stuff</a>
            <a href="#">Last of us</a>
          </nav>

          <cite></cite>

          <address>
            2014 © Koding, Inc. 358 Brannan Street, San Francisco, CA, 94107
          </address>
          <span class="we-love-you">Lovingly made in Istanbul & San Francisco <3</span>

          <div class="social-links">
            <a href="#">TWITTER</a>
            <a href="#">FACEBOOK</a>
            <a href="#">INSTAGRAM</a>
          </div>
        </div>
      </footer>
    """


