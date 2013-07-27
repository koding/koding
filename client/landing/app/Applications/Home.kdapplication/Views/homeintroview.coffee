class HomeIntroView extends JView

  constructor:(options = {}, data)->

    options.tagName or= "section"
    options.domId   or= "home-intro"

    super options, data

    @slogan = new KDCustomHTMLView
      tagName  : 'h2'
      cssClass : 'slogan'
      partial  : 'A new way for<br/>developers to work.'

    @subSlogan = new KDCustomHTMLView
      tagName  : 'h3'
      cssClass : 'slogan-continues'
      partial  : 'Koding is your new development computer, sign up to get a free VM and use it in your browser.'

    @form = new KDFormViewWithFields
      fields          :
        github        :
          name        : 'gh'
          title       : 'Sign up with GitHub'
          placeholder : 'Desired username'
          itemClass   : KDButtonView
          cssClass    : 'register gh-gray'
          type        : 'button'
          icon        : yes
          iconClass   : 'octocat'
        separator     :
          name        : 'or'
          partial     : 'or'
          itemClass   : KDCustomHTMLView
          tagName     : 'span'
        # firstname     :
        #   name        : 'firstname'
        #   placeholder : 'First name'
        #   cssClass    : 'half'
        #   nextElement     :
        #     lastname      :
        #       name        : 'lastname'
        #       placeholder : 'Last name'
        #       cssClass    : 'half'
        username      :
          name        : 'username'
          placeholder : 'Desired username'
        email         :
          name        : 'email'
          placeholder : 'Your email address'
          type        : 'email'
        password      :
          name        : 'password'
          placeholder : 'Type a password'
          type        : 'password'
      buttons         :
        register      :
          title       : 'REGISTER'
          cssClass    : 'register orange'
          type        : 'submit'
          callback    : -> log 'submitted'

    @toc = new KDCustomHTMLView
      cssClass : 'toc'
      partial  : 'By signing up, you agree to our <a href="#">terms of service</a> and <a href="#">privacy policy</a>.'

    @videoThumb = new KDCustomHTMLView
      tagName  : 'a'
      partial  : "<i></i><img src='/images/timedude.jpg'/>"
      click    : ->
        w = 800
        h = 450
        window.open "/timedude.html",
          "Koding and the Timedude!",
          "width=#{w},height=#{h},left=#{Math.floor (screen.width/2) - (w/2)},top=#{Math.floor (screen.height/2) - (h/2)}"

  show:->
    @unsetClass 'out'

  hide:->
    @setClass 'out'

  pistachio:->
    if KD.isLoggedIn()
      """
      <div>
      {{> @slogan}}
      {{> @subSlogan}}
      </div>
      <aside>
      <ul>
      <li>{{> @videoThumb}}</li>
      </ul>
      </aside>
      """
    else
      """
      <div>
      {{> @slogan}}
      {{> @subSlogan}}
      <ul>
      <li>{{> @videoThumb}}</li>
      </ul>
      </div>
      <aside>
      {{> @form}}
      {{> @toc}}
      </aside>
      """

