class HomePage extends JView

  constructor:(options = {}, data)->

    options.domId = 'home-page'

    super options, data

    @pricingButton = new KDButtonView
      title       : 'Get Koding for your intranet<cite>Starting from $5 per user</cite>'
      cssClass    : 'solid green shadowed pricing'
      icon        : 'yes'
      iconClass   : 'dollar'
      callback    : -> log 'lolololoooo'

    @registerForm = new RegisterInlineForm
      callback    : (formData)-> @doRegister formData

    @githubLink   = new KDCustomHTMLView
      tagName     : "a"
      partial     : "GitHub"
      click       : ->
        KD.singletons.oauthController.openPopup "github"

    @markers = new MarkerController

  viewAppended:->

    super

    vmMarker = @markers.create 'vms',
      client    : '#home-page .laptop .teamwork'
      container : this
      wait      : 1000
      offset    :
        top     : 150
        left    : 50

    navMarker = @markers.create 'nav',
      client    : '#home-page .laptop .teamwork'
      container : this
      wait      : 1300
      offset    :
        top     : -30
        left    : 240

    chatMarker = @markers.create 'chat',
      client    : '#home-page .laptop .teamwork'
      container : this
      wait      : 1600
      offset    :
        top     : 150
        left    : 800

    playMarker = @markers.create 'play',
      client    : '#home-page .laptop .teamwork'
      container : this
      wait      : 1900
      offset    :
        top     : 275
        left    : 500


  pistachio:->

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
        <h3>Or you can sign up using {{> @githubLink}}<span></span></a></h2>
      </main>
      <figure class='laptop'>
        <section class='teamwork'></section>
      </figure>
      <section id='home-features' class='clearfix'>
        <div class='appstore clearfix'>
          <span class='icon'></span>
          <article>
            <h4>APPSTORE</h4>
            Koding apps to speed up your noob processes
          </article>
        </div>
        <div class='teamwork clearfix'>
          <span class='icon'></span>
          <article>
            <h4>TEAMWORK</h4>
            Collaborative development environment for your pleasure
          </article>
        </div>
        <div class='social clearfix'>
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
