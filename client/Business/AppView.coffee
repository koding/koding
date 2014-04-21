class BusinessView extends KDView

  constructor: ->

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
            <h2>Koding for Busy People</h2>
            <p>
              Have your private Koding in the cloud, with your rules, your apps and your team.
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
            <i class="gameplan icon"></i>
            <h5>Total control over the big picture</h5>
            <p>
              Never miss a thing. Who is working on what, who needs help,
              what needs to be done. Look back into the progress of your
              team’s progress.
            </p>
          </article>
          <article class="feature">
            <i class="ruler icon"></i>
            <h5>Scale as you grow</h5>
            <p>
              Fully scalable environments with customizable stacks gives you
              the ability to scale as you get bigger in size. Size matters.
            </p>
          </article>
          <article class="feature">
            <i class="box-open icon"></i>
            <h5>Ready to roll VM’s</h5>
            <p>
              Stop wasting time setting up environments for every single
              team member as they join in. With a single click,
              they are ready to go.
            </p>
          </article>
          <article class="feature">
            <i class="starflag icon"></i>
            <h5>White Label</h5>
            <p>
              To suit your brand guidelines, fully customisable Koding
              experience in your intranet.
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
            <a href='#'>KODING BLOG</a>
            <a href='#'>MEETUPS</a>
            <a href='#'>NEWSLETTER</a>
            <a href='http://stories.koding.com'>TESTIMONALS</a>
            <a href='https://koding-cdn.s3.amazonaws.com/brand/koding-logo.pdf'>BRAND GUIDELINES</a>
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


