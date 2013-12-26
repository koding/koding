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
        <h1>SOMETHING SUPER EXCITING GOES HERE</h1>
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
        <h2>GROUPS ARE LIKE BALOONS</h2>
        <h3>Something super simple and super descriptive goes here</h3>
        <figure></figure>
      </section>
    """


KD.introView = new HomePage
KD.introView.appendToDomBody()