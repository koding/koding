class HomePage extends JView

  constructor:(options = {}, data)->

    options.domId = 'home-page'

    super options, data

    @email        = new KDInputView
      placeholder : 'your@email.com'

    @username     = new KDInputView
      placeholder : 'desired username'

    @signUp       = new KDButtonView
      title       : 'Sign up'
      cssClass    : 'solid red shadowed'
      type        : 'submit'

    @pricingButton = new KDButtonView
      title       : 'Get Koding for your intranet<cite>Starting from $5 per user</cite>'
      cssClass    : 'solid green shadowed pricing'
      icon        : 'yes'
      iconClass   : 'dollar'
      callback    : -> log 'lolololoooo'

    @registerForm = new KDFormView
      callback    : (formData)-> log formData

    @registerForm.once 'viewAppended', =>
      @registerForm.addSubView @email
      @registerForm.addSubView @username
      @registerForm.addSubView @signUp

  pistachio:->

    # <nav>
    #   <ul>
    #     <li><a href="/About">About</a></li>
    #     <li><a href="/Pricing">Pricing</a></li>
    #     <li><a href="/Features">Features</a></li>
    #     <li><a href="/About">Learn</a></li>
    #     <li><a href="/Team">Team</a></li>
    #     <li><a href="/Jobs">Jobs</a></li>
    #   </ul>
    # </nav>


    """
      <header id='home-header'>
        <div class="inner-container">
          <a href="/" class="logo"><cite></cite></a>
          <a href="/Login" class="login fr">LOGIN</a>
        </div>
      </header>
      <main>
        <h1 class='big-header'>SOMETHING SUPER EXCITING GOES HERE</h1>
        <h2>Something super simple and super descriptive goes here</h2>
        {{> @registerForm}}
        <h3>Or you can sign up using <a href='/Register/GitHub'><strong>GitHub</strong><span></span></a></h2>
      </main>
      <figure class='laptop'>
        <section class='teamwork'>
          <span class='marker'><i></i></span>
        </section>
        <section></section>
        <section></section>
      </figure>
      <section id='home-features' class='clearfix'>
        <div class='appstore'>
          <span class='icon'></span>
          <article>
            <h4>APPSTORE</h4>
            Koding apps to speed up your noob processes
          </article>
        </div>
        <div class='teamwork'>
          <span class='icon'></span>
          <article>
            <h4>TEAMWORK</h4>
            Collaborative development environment for your pleasure
          </article>
        </div>
        <div class='social'>
          <span class='icon'></span>
          <article>
            <h4>SOCIAL</h4>
            Ask the masters of code, help out the poor noob.
          </article>
        </div>
      </section>
      <section id='home-groups'>
        <h2 class='big-header'>GROUPS ARE LIKE BALOONS</h2>
        <h3>Something super simple and super descriptive goes here</h3>
        <figure class='education'></figure>
        <figure class='browser'></figure>
        <div class='group-features clearfix'>
          <div class='white-label'>
            <span class='icon'></span>
            <article>
              <h4>WHITE LABEL KODING</h4>
              Etiam turpis ante, aliquam id mattis condimentum, adipiscing vitae ipsum. Phasellus ultricies diam ligula, at pellentesque ligula lobortis eget.
            </article>
          </div>
          <div class='school'>
            <span class='icon'></span>
            <article>
              <h4>USE IT IN YOUR SCHOOL</h4>
              Etiam turpis ante, aliquam id mattis condimentum, adipiscing vitae ipsum. Phasellus ultricies diam ligula, at pellentesque ligula lobortis eget.
            </article>
          </div>
          <div class='project'>
            <span class='icon'></span>
            <article>
              <h4>CREATE PROJECT GROUPS</h4>
              Etiam turpis ante, aliquam id mattis condimentum, adipiscing vitae ipsum. Phasellus ultricies diam ligula, at pellentesque ligula lobortis eget.
            </article>
          </div>
        </div>
        {{> @pricingButton}}
      </section>
      <section id='home-bottom'>
        <h2 class='big-header'>IF YOU ARE READY TO GO, LET’S DO THIS</h2>
        <h3>Something super simple and super descriptive goes here</h3>
      </section>
      <footer class='clearfix'>
        <div class='fl'>
          <a href="/" class="logo"><cite></cite></a>
          <address>
          #{(new Date).getFullYear()} © Koding, Inc. </br>358 Brannan Street, San Francisco, CA, 94107
          </address>
        </div>
        <nav>
          <a href="/About">About</a>
          <a href="mailto:hello@koding.com">Contact</a>
          <a href="http://learn.koding.com/">University</a>
          <a href="http://koding.github.io/jobs/">Jobs</a>
          <a href="/Blog">Blog</a>
          <a href="/Status">Status</a>
        </nav>
      </footer>
    """


KD.introView = new HomePage
KD.introView.appendToDomBody()