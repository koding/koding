class HomeView extends KDView

  constructor:->
    super

    {router} = KD.singletons

    @pricingButton = new KDButtonView
      title       : "See Pricing"
      style       : "solid thin medium thin-white"
      callback    : -> router.handleRoute "/Pricing"

    @signUpButton = new KDButtonView
      title       : "Sign Up Now"
      style       : "solid medium green"
      callback    : -> router.handleRoute "/Register"

  viewAppended: JView::viewAppended

  pistachio : ->
    """
      <section class="introduction">
        <div class="inner-container clearfix">
          <article>
            <h2>Develop. Together!</h2>
            <p>
              Koding gives you the necessary environment to start developing your apps, run them, collaborate and share with the world.
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
            <img src="/a/images/ss-terminal.jpg" alt="Terminal">
          </figure>
          <figure class="third">
            <img src="/a/images/ss-environments.jpg" alt="Environments">
          </figure>
        </div>
      </section>

      <section class="features">
        <div class="inner-container clearfix">
          <article class="feature">
            <i class="bubbles icon"></i>
            <h5>Integrated social tools</h5>
            <p>
              Share with the community, learn from the experts or help those
              who have yet to start coding. Socialize with like minded people
              and have fun.
            </p>
          </article>
          <article class="feature">
            <i class="team icon"></i>
            <h5>There is no “I” in Team</h5>
            <p>
              Collaborative development environment for lecture groups,
              pair programming, or simply for sharing what you're doing with
              a total stranger
            </p>
          </article>
          <article class="feature">
            <i class="box icon"></i>
            <h5>Yeah, there’s an app for that</h5>
            <p>
              Speed up with user contributed apps, or create your own app,
              Koding has a great toolset to interact with VMs and to build
              UIs around.
            </p>
          </article>
          <article class="feature">
            <i class="settings icon"></i>
            <h5>Control freaks?</h5>
            <p>
              Micro manage your working environment structure.
              Go granular, add VM’s, add storage, double up the database,
              go nuts as you scale.
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

      <section class='check-out'>
        <h3><a href='/Pricing'>Check out our price plans</a> and get started with Koding right away!</h3>
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


