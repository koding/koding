class HomeIntroView extends JView

  constructor:(options = {}, data)->

    # options.tagName or= "section"
    options.domId   or= "home-intro"

    super options, data

    router = KD.getSingleton 'router'

    @slogan     = new KDCustomHTMLView
      partial   : "A new way for developers to work"
      cssClass  : "slogan"

    @subSlogan     = new KDCustomHTMLView
      partial   : "Software development has finally evolved,<br> It's now social, in the browser and free!"
      cssClass  : "sub-slogan"

    @emailSignupButton  = new KDButtonView
      cssClass  : "email"
      partial   : "<i></i>Sign up <span>with email</span>"
      callback  : -> router.handleRoute '/Register'

    @gitHubSignupButton = new KDButtonView
      cssClass  : "github"
      partial   : "<i></i>Sign up <span>with gitHub</span>"
      callback  : -> KD.getSingleton("oauthController").openPopup "github"

    @learnMoreLink = new KDCustomHTMLView
      partial   : '▾ scroll down to learn more ▾'
      cssClass  : 'learnmore'

  show:-> @unsetClass 'out'

  hide:-> @setClass 'out'

  # viewAppended:->
  #   super
    # @utils.wait 2000, => @try.setClass 'in'
  pistachio:->
    if KD.isLoggedIn()
      """
      <section>
        <div>
          {{> @slogan}}
          {{> @subSlogan}}
        </div>
        <aside>
          <ul>
            <li>{{> @timedudeThumb}}</li>
          </ul>
        </aside>
      </section>
      {{> @try}}
      {{> @counterBar}}
      """
    else
      """
      <section>
        {{> @slogan}}
        {{> @subSlogan}}
        <div class="buttons">
          {{> @emailSignupButton}}
          {{> @gitHubSignupButton}}
        </div>
        {{> @learnMoreLink}}
      </section>
      """



    # @form = new KDFormViewWithFields
    #   fields          :
    #     github        :
    #       name        : 'gh'
    #       title       : 'Sign up with GitHub'
    #       itemClass   : KDButtonView
    #       cssClass    : 'register gh-gray'
    #       type        : 'button'
    #       icon        : yes
    #       iconClass   : 'octocat'
    #     separator     :
    #       name        : 'or'
    #       partial     : 'or'
    #       itemClass   : KDCustomHTMLView
    #     register      :
    #       title       : 'Sign up with e-mail'
    #       itemClass   : KDButtonView
    #       cssClass    : 'register orange'
    #       type        : 'button'
    #       callback    : -> router.handleRoute '/Register'
        # separator     :
        #   name        : 'or'
        #   partial     : 'or'
        #   itemClass   : KDCustomHTMLView
        # login         :
        #   tagName     : 'span'
        #   itemClass   : KDButtonView
        #   title       : 'Already a user? Login'
        #   cssClass    : 'login gray'
        #   type        : 'button'
        #   callback    : -> router.handleRoute '/Login'
        # firstname     :
        #   name        : 'firstname'
        #   placeholder : 'First name'
        #   cssClass    : 'half'
        #   nextElement     :
        #     lastname      :
        #       name        : 'lastname'
        #       placeholder : 'Last name'
        #       cssClass    : 'half'
        # username      :
        #   name        : 'username'
        #   placeholder : 'Desired username'
        # email         :
        #   name        : 'email'
        #   placeholder : 'Your email address'
        #   type        : 'email'
        # password      :
        #   name        : 'password'
        #   placeholder : 'Type a password'
        #   type        : 'password'
      # buttons         :

    # @videoThumb = new KDCustomHTMLView
    #   tagName  : 'a'
    #   partial  : "<i></i><img src='/images/timedude.jpg'/>"
    #   click    : ->
    #     w = 800
    #     h = 450
    #     window.open "/timedude.html",
    #       "Koding and the Timedude!",
    #       "width=#{w},height=#{h},left=#{Math.floor (screen.width/2) - (w/2)},top=#{Math.floor (screen.height/2) - (h/2)}"

