JView                                 = require './../core/jview'
CustomLinkView                        = require './../core/customlinkview'
LoginInlineForm                       = require './loginform'
RegisterInlineForm                    = require './registerform'
RedeemInlineForm                      = require './redeemform'
RecoverInlineForm                     = require './recoverform'
ResetInlineForm                       = require './resetform'
ResendEmailConfirmationLinkInlineForm = require './resendmailconfirmationform'
FinishRegistrationForm                = require './finishregistrationform'
LoginOptions                          = require './loginoptions'
RegisterOptions                       = require './registeroptions'
MainControllerLoggedOut               = require './../core/maincontrollerloggedout'

module.exports = class LoginView extends JView

  stop = KD.utils.stopDOMEvent

  backgroundImages  = [
    [ 'Charlie Foster', 'http://www.flickr.com/photos/charliefoster/' ]
    [ 'Dietmar Becker', 'http://pican.de/' ]
    [ 'Marcin Czerwinski', 'http://www.station75.com/' ]
    [ 'Marcin Czerwinski', 'http://www.station75.com/' ]
    [ 'Anton Sulsky', 'http://www.flickr.com/photos/discomethod/sets/72157635620513053/' ]
    [ 'Joeri Römer', 'http://www.jfrwebdesign.nl/' ]
    [ 'Zugr', 'http://be.net/Zugr' ]
    [ 'Mark Doda', '' ]
    [ 'Rick Waalders', 'http://www.twitter.com/rickwaalders' ]
    [ 'Vadim Sherbakov', 'http://madebyvadim.com/' ]
    [ 'Zwaddi', '' ]
    [ 'Zugr', 'http://be.net/Zugr' ]
    [ 'Romain Briaux', 'http://www.romainbriaux.fr/' ]
    [ 'petradr', 'https://twitter.com/Petchy19' ]
    [ 'Riley Briggs', 'http://rileyb.me/' ]
    [ 'Chloe Benko-Prieur', 'http://chloecolorphotography.tumblr.com/' ]
  ]

  backgroundImageNr = MainControllerLoggedOut.loginImageIndex

  do ->
    image      = new Image
    bgImageUrl = "/a/site.landing/images/unsplash/#{backgroundImageNr}.jpg"
    image.src  = bgImageUrl

    image.classList.add 'off-screen-login-image'

    document.head.appendChild (new KDCustomHTMLView {
      tagName    : 'style'
      partial    : ".kdview.login-screen:after { background-image : url('#{bgImageUrl}')}"
    }).getElement()


  constructor:(options = {}, data)->

    options.cssClass = 'login-screen login'

    super options, data

    @logo = new KDCustomHTMLView
      tagName    : 'a'
      cssClass   : 'koding-logo'
      partial    : '<cite></cite>'
      attributes : href : '/'

    @backToLoginLink = new CustomLinkView
      title       : 'Sign In'
      href        : '/Login'
      click       : ->
        KD.mixpanel 'Login button form in /Login, click'

    @goToRecoverLink = new CustomLinkView
      cssClass    : 'forgot-link'
      title       : 'Forgot your password?'
      testPath    : 'landing-recover-password'
      href        : '/Recover'

    @goToRegisterLink = new CustomLinkView
      title       : 'Sign up'
      href        : '/Register'

    @formHeader = new KDCustomHTMLView
      tagName     : "h4"
      cssClass    : "form-header"
      click       : (event)->
        return  unless $(event.target).is 'a.register'
        KD.mixpanel 'Register button form in /Login, click'

    if KD.utils.oauthEnabled() is yes
      @github          = new KDCustomHTMLView
        tagName     : "a"
        cssClass    : "github-login"
        partial     : "Sign in using <strong>GitHub</strong>"
        click       : ->
          KD.mixpanel "Github auth button in /Login, click"
          KD.singletons.oauthController.openPopup "github"
    else
      @github = new KDCustomHTMLView
        tagName     : "a"
        cssClass    : "github-login"
        partial     : "<a href='http://koding.com'>Learn more</a>"

    @github.setPartial "<span class='button-arrow'></span>"

    # @loginOptions = new LoginOptions
    #   cssClass : "login-options-holder log"

    # @registerOptions = new RegisterOptions
    #   cssClass : "login-options-holder reg"

    @loginForm = new LoginInlineForm
      cssClass : "login-form"
      testPath : "login-form"
      callback : (formData)=>
        KD.mixpanel "Login submit, click"
        @doLogin formData

    @registerForm = new RegisterInlineForm
      cssClass : "login-form"
      testPath : "register-form"
      callback : (formData) =>
        KD.mixpanel "Register submit, click"
        @showPasswordModal formData, @registerForm

    @redeemForm = new RedeemInlineForm
      cssClass : "login-form"
      callback : (formData)=>
        KD.mixpanel "Redeem submit, click"
        @doRedeem formData

    @recoverForm = new RecoverInlineForm
      cssClass : "login-form"
      callback : (formData)=>
        KD.mixpanel "Recover password submit, click"
        @doRecover formData

    @resendForm = new ResendEmailConfirmationLinkInlineForm
      cssClass : "login-form"
      callback : (formData)=>
        @resendEmailConfirmationToken formData
        KD.mixpanel "Resend email button, click"

    @resetForm = new ResetInlineForm
      cssClass : "login-form"
      callback : (formData)=>
        @doReset formData

    @finishRegistrationForm = new FinishRegistrationForm
      cssClass  : "login-form foobar"
      callback  : (formData) =>
        @doFinishRegistration formData

    @headBanner = new KDCustomHTMLView
      domId    : "invite-recovery-notification-bar"
      cssClass : "invite-recovery-notification-bar hidden"
      partial  : "..."

    setValue = (field, value)=>
      @registerForm[field]?.input?.setValue value
      @registerForm[field]?.placeholder?.setClass 'out'

    mainController = KD.getSingleton "mainController"
    mainController.on "ForeignAuthCompleted", (provider)=>
      isUserLoggedIn = KD.isLoggedIn()
      params = {isUserLoggedIn, provider}

      (KD.getSingleton 'mainController').handleOauthAuth params, (err, resp)=>
        if err
          showError err
          KD.mixpanel "Authenticate with oauth, fail", {provider}
        else
          {account, replacementToken, isNewUser, userInfo} = resp
          if isNewUser
            KD.getSingleton('router').handleRoute '/Register'
            @animateToForm "register"
            for own field, value of userInfo
              setValue field, value

            KD.mixpanel "Github auth register, success"
          else
            if isUserLoggedIn
              mainController.emit "ForeignAuthSuccess.#{provider}"
              KD.mixpanel "Authenticate with oauth, success", {provider}
              new KDNotificationView
                title : "Your #{provider.capitalize()} account has been linked."
                type  : "mini"

            else
              @afterLoginCallback err, {account, replacementToken}
              KD.mixpanel "Github auth login, success"


  viewAppended:->


    @setTemplate @pistachio()
    @template.update()

    query = KD.utils.parseQuery document.location.search.replace "?", ""

    if query.warning
      suffix  = if query.type is "comment" then "post a comment" else "like an activity"
      message = "You need to be logged in to #{suffix}"

      KD.getSingleton("mainView").createGlobalNotification
        title      : message
        type       : "yellow"
        content    : ""
        closeTimer : 4000
        container  : this

    KD.utils.defer => @setClass 'shown'

  pistachio:->
      # {{> @loginOptions}}
      # {{> @registerOptions}}
    """
    <div class='tint'></div>
    {{> @logo }}
    <div class="flex-wrapper">
      {{> @formHeader}}
      <div class="login-form-holder lf">
        {{> @loginForm}}
      </div>
      <div class="login-form-holder rf">
        {{> @registerForm}}
      </div>
      <div class="login-form-holder frf">
        {{> @finishRegistrationForm}}
      </div>
      <div class="login-form-holder rdf">
        {{> @redeemForm}}
      </div>
      <div class="login-form-holder rcf">
        {{> @recoverForm}}
      </div>
      <div class="login-form-holder rsf">
        {{> @resetForm}}
      </div>
      <div class="login-form-holder resend-confirmation-form">
        {{> @resendForm}}
      </div>
      <div class="login-footer">
        {{> @github}} {{> @goToRecoverLink}}
      </div>
    </div>
    <footer>
      <a href="/acceptable.html" target="_blank">Acceptable user policy</a><a href="/copyright.html" target="_blank">Copyright/DMCA guidelines</a><a href="/tos.html" target="_blank">Terms of service</a><a href="/privacy.html" target="_blank">Privacy policy</a><a href="#{backgroundImages[backgroundImageNr][1]}" target="_blank"><span>photo by </span>#{backgroundImages[backgroundImageNr][0]}</a>
    </footer>
    """

  doReset:({recoveryToken, password})->
    KD.remote.api.JPasswordRecovery.resetPassword recoveryToken, password, (err, username)=>
      if err
        new KDNotificationView
          title : "An error occurred: #{err.message}"
      else
        @resetForm.button.hideLoader()
        @resetForm.reset()
        @headBanner.hide()
        @doLogin {username, password}

  doRecover:(formData)->
    KD.remote.api.JPasswordRecovery.recoverPassword formData['username-or-email'], (err)=>
      @recoverForm.button.hideLoader()
      if err
        new KDNotificationView
          title : "An error occurred: #{err.message}"
      else
        @recoverForm.reset()
        {entryPoint} = KD.config
        KD.getSingleton('router').handleRoute '/Login', {entryPoint}
        new KDNotificationView
          title     : "Check your email"
          content   : "We've sent you a password recovery code."
          duration  : 4500

        KD.mixpanel "Recover password, success"

  resendEmailConfirmationToken:(formData)->
    KD.remote.api.JPasswordRecovery.recoverPassword formData['username-or-email'], (err)=>
      @resendForm.button.hideLoader()
      if err
        new KDNotificationView
          title : "An error occurred: #{err.message}"
      else
        @resendForm.reset()
        {entryPoint} = KD.config
        KD.getSingleton('router').handleRoute '/Login', {entryPoint}
        new KDNotificationView
          title     : "Check your email"
          content   : "We've sent you a confirmation mail."
          duration  : 4500


  showExtraInformation : (formData, form) ->
    {mainView} = KD.singletons

    mainView.setClass 'blur'

    {gravatar, email, password}     = formData

    if gravatar is '"User not found"'
      gravatar              =
        dummy               : yes
        photos              : [
          (value            : 'https://koding-cdn.s3.amazonaws.com/square-avatars/default.avatar.80.png')
        ]
        preferredUsername   : ''

    else
      gravatar                      = (JSON.parse gravatar)['entry'][0]

    {preferredUsername, photos}     = gravatar
    givenName                       = gravatar.name?.givenName
    familyName                      = gravatar.name?.familyName

    fields                  = {}

    fields['photo']         =
      itemClass             : KDCustomHTMLView
      tagName               : 'img'
      attributes            :
        src                 : photos[0].value

    fields['email']         =
      itemClass             : KDCustomHTMLView
      partial               : email

    fields['username']      =
      name                  : 'username'
      defaultValue          : preferredUsername
      label                 : 'Username'
      nextElement           :
        suffix              :
          itemClass         : KDCustomHTMLView
          cssClass          : 'suffix'
          partial           : '.koding.io'

    if givenName
      fields['firstName']   =
        defaultValue        : givenName
        label               : 'First Name'

    if familyName
      fields['lastName']    =
        defaultValue        : familyName
        label               : 'Last Name'


    modal = new KDModalViewWithForms
      cssClass                        : 'extra-info password'
      width                           : 360
      height                          : 'auto'
      overlay                         : yes
      tabs                            :
        forms                         :
          extraInformation            :
            fields                    : fields
            buttons                   :
              continue                :
                title                 : "LET'S GO"
                style                 : "solid green medium"
                type                  : "submit"

    unless gravatar.dummy
      modal.addSubView new KDCustomHTMLView
        partial  : 'Profile info fetched from Gravatar.'
        cssClass : 'description'

    modal.once 'KDObjectWillBeDestroyed', ->
      mainView.unsetClass 'blur'
      form.button.hideLoader()


  showPasswordModal: (formData, form) ->

    if no in [form.email.input.valid, form.username.input.valid]
      return form.button.hideLoader()

    {mainView} = KD.singletons

    mainView.setClass 'blur'

    modal = new KDModalViewWithForms
      cssClass                : 'password'
      width                   : 600
      height                  : 'auto'
      overlay                 : yes
      title                   : 'Almost there, please enter a strong password.'
      tabs                    :
        forms                 :
          password            :
            callback          : (passwordForm) =>

              KD.mixpanel 'Register submit, click'

              formData.password        = passwordForm.password
              formData.passwordConfirm = passwordForm.passwordConfirm

              @doRegister formData, form
              modal.destroy()

            fields                    :
              password                :
                type                  : 'password'
                cssClass              : 'half'
                name                  : 'password'
                placeholder           : 'password'
                validate              :
                  events              :
                    passwordCheck     : 'keyup'
                  rules               :
                    passwordCheck     : (input, event)=>
                      passwordForm  = modal.modalTabs.forms.password
                      {result, msg} = @checkForPasswords input, passwordForm.inputs.confirm
                      @changeButtonState passwordForm.buttons.submit, result
                      modal.setTitle msg
                nextElement           :
                  confirm             :
                    cssClass          : 'half'
                    type              : 'password'
                    name              : 'passwordConfirm'
                    placeholder       : 'confirm password'
                    validate          :
                      events          :
                        passwordCheck : 'keyup'
                      rules           :
                        passwordCheck : (input, event)=>
                          passwordForm  = modal.modalTabs.forms.password
                          {result, msg} = @checkForPasswords input, passwordForm.inputs.password
                          @changeButtonState passwordForm.buttons.submit, result
                          modal.setTitle msg
            buttons           :
              submit          :
                cssClass      : 'solid green medium'
                type          : 'submit'
                title         : 'Let\'s go'
                disabled      : yes

    modal.once 'KDObjectWillBeDestroyed', ->
      mainView.unsetClass 'blur'
      form.button.hideLoader()

    modal.once 'viewAppended', ->

      modal.addSubView new KDCustomHTMLView
        partial : """<div class='hint accept-tos'>By creating an account, you accept Koding's <a href="/tos.html" target="_blank"> Terms of Service</a> and <a href="/privacy.html" target="_blank">Privacy Policy.</a></div>"""

      KD.utils.defer ->
        modal.modalTabs.forms.password.inputs.password.setFocus()

  checkForPasswords: (password, confirm) ->

    vals = [password.getValue(), confirm.getValue()]
    check1 = vals.first.length > 7
    check2 = vals.last.length > 7
    check3 = vals.first is vals.last

    return result : no, msg : "Passwords must match!"  if check1 and not check2
    return result : no, msg : "Passwords should be at least 8 characters."  if not check1 or not check2
    return result : no, msg : "Passwords must match!"  unless check3

    return result : yes, msg : "Looks good, go ahead!"  if check1 and check2 and check3


  changeButtonState: (button, state) ->

    if state
      button.setClass 'green'
      button.unsetClass 'red'
      button.enable()
    else
      button.setClass 'red'
      button.unsetClass 'green'
      button.disable()


  doRegister: (formData, form) ->

    formData.agree    = 'on'

    form or= @registerForm
    form.notificationsDisabled = yes
    form.notification?.destroy()

    {username, redirectTo} = formData

    query = ''
    if redirectTo is 'Pricing'
      { planInterval, planTitle } = formData
      query = KD.utils.stringifyQuery {planTitle, planInterval}
      query = "?#{query}"

    $.ajax
      url         : "/Register"
      data        : formData
      type        : 'POST'
      xhrFields   : withCredentials : yes
      success     : ->
        # KD.mixpanel.alias username
        KD.mixpanel 'Signup, success'
        document.cookie = 'newRegister=true'

        return location.replace "/#{redirectTo}#{query}"

      error       : (xhr) ->
        {responseText} = xhr
        form.button.hideLoader()
        form.notificationsDisabled = no
        new KDNotificationView title : responseText
        form.emit 'SubmitFailed', responseText


  doFinishRegistration: (formData) ->
    (KD.getSingleton 'mainController').handleFinishRegistration formData, @bound 'afterLoginCallback'

  doLogin: (formData)->

    {username, password, redirectTo} = formData

    query = ''
    if redirectTo is 'Pricing'
      { planInterval, planTitle } = formData
      query = KD.utils.stringifyQuery {planTitle, planInterval}
      query = "?#{query}"

    $.ajax
      url         : '/Login'
      data        : { username, password }
      type        : 'POST'
      xhrFields   : withCredentials : yes
      success     : -> location.replace "/#{redirectTo}#{query}"
      error       : (xhr) =>
        {responseText} = xhr
        new KDNotificationView title : responseText
        @loginForm.button.hideLoader()



  runExternal = (token)->
    KD.getSingleton("kiteController").run
      kiteName        : "externals"
      method          : "import"
      correlationName : " "
      withArgs        :
        value         : token
        serviceName   : "github"
        userId        : KD.whoami().getId()
      ,
    (err, status)-> log "Status of fetching stuff from external: #{status}"


  afterLoginCallback: (err, params={})->
    @loginForm.button.hideLoader()
    {entryPoint} = KD.config
    if err
      showError err
      @loginForm.resetDecoration()
      @$('.flex-wrapper').removeClass 'shake'
      KD.utils.defer => @$('.flex-wrapper').addClass 'animate shake'
    else
      {account} = params
      # check and set preferred BE domain for Koding
      # prevent user from seeing the main wiev
      KD.utils.setPreferredDomain account if account

      # this implementation below needs to be handled in the server (express)
      # otherwise it makes the login experience slower
      # or we can do it after login is performed and page is reloaded
      # - SY

      window.location.replace '/'


      # firstRoute = KD.getSingleton('router').visitedRoutes.first

      # if firstRoute and /^\/(?:Reset|Register|Confirm|R)\//.test firstRoute
      #   firstRoute = '/'

      # @appStorage = KD.getSingleton('appStorageController').storage 'Login', '1.0'
      # @appStorage.fetchValue "redirectTo", (redirectTo) =>
      #   if redirectTo
      #     firstRoute = "/#{redirectTo}"
      #     @appStorage.unsetKey "redirectTo", (err) ->
      #       warn "Failed to reset redirectTo", err  if err

      #   KD.getSingleton('appManager').quitAll()
      #   KD.getSingleton('router').handleRoute firstRoute or '/Activity', {replaceState: yes, entryPoint}
      #   KD.getSingleton('groupsController').on 'GroupChanged', =>
      #     @headBanner?.hide()
      #     @loginForm.reset()

      #   new KDNotificationView
      #     cssClass  : "login"
      #     title     : "<span></span>Happy Koding!"
      #     # content   : "Successfully logged in."
      #     duration  : 2000
      #   @loginForm.reset()

      #   KD.mixpanel "Login, success"
      #   if redirectTo
      #     window.location.reload()
      #   else
      #     window.location.replace '/Activity'

  doRedeem:({inviteCode})->
    return  unless KD.config.entryPoint?.slug or KD.isLoggedIn()

    KD.remote.cacheable KD.config.entryPoint.slug, (err, [group])=>
      group.redeemInvitation inviteCode, (err)=>
        @redeemForm.button.hideLoader()
        return KD.notify_ err.message or err  if err
        KD.notify_ 'Success!'
        KD.getSingleton('mainController').accountChanged KD.whoami()

        KD.mixpanel "Redeem, success"

  hide: (callback) ->

    @$('.flex-wrapper').removeClass 'expanded'
    @emit "LoginViewHidden"
    @setClass 'hidden'
    callback?()


  show: (callback) ->

    @unsetClass 'hidden'
    @emit "LoginViewShown"
    callback?()

  # click:(event)->
  #   if $(event.target).is('.login-screen')
  #     @hide ->
  #       router = KD.getSingleton('router')
  #       routed = no
  #       for route in router.visitedRoutes by -1
  #         {entryPoint} = KD.config
  #         routeWithoutEntryPoint =
  #           if entryPoint?.type is 'group' and entryPoint.slug
  #           then route.replace "/#{entryPoint.slug}", ''
  #           else route
  #         unless routeWithoutEntryPoint in ['/Login', '/Register', '/Recover', '/ResendToken']
  #           router.handleRoute route
  #           routed = yes
  #           break
  #       router.clear()  unless routed

  setCustomDataToForm: (type, data)->
    formName = "#{type}Form"
    @[formName].addCustomData data
    # @resetForm.addCustomData {recoveryToken}

  setCustomData: (data) ->

    @setCustomDataToForm 'login', data
    @setCustomDataToForm 'register', data

    @setFormHeaderPartial data


  getRegisterLink: (data = {}) ->

    queryString = KD.utils.stringifyQuery data
    queryString = "?#{queryString}"  if queryString.length > 0

    link = "/Register#{queryString}"


  animateToForm: (name)->

    @unsetClass 'register recover login reset home resendEmail finishRegistration'
    @emit 'LoginViewAnimated', name
    @setClass name
    @$('.flex-wrapper').removeClass 'three one'

    @formHeader.hide()
    @github.show()
    @goToRecoverLink.show()

    switch name
      when "register"
        @registerForm.email.input.setFocus()
      when "finishRegistration"
        @finishRegistrationForm.username.input.setFocus()
      when "redeem"
        @$('.flex-wrapper').addClass 'one'
        @redeemForm.inviteCode.input.setFocus()
      when "login"
        @formHeader.show()
        @formHeader.updatePartial @generateFormHeaderPartial()
        @loginForm.username.input.setFocus()
      when "recover"
        @$('.flex-wrapper').addClass 'one'
        @github.hide()
        @goToRecoverLink.hide()
        @recoverForm.usernameOrEmail.input.setFocus()
      when "resendEmail"
        @$('.flex-wrapper').addClass 'one'
        @resendForm.usernameOrEmail.input.setFocus()
      when "reset"
        @formHeader.show()
        @formHeader.updatePartial "Set your new password below"
        @goToRecoverLink.hide()
        @github.hide()


  generateFormHeaderPartial: (data = {}) ->
    "Don't have an account yet? <a class='register' href='#{@getRegisterLink data}'>Sign up</a>"


  setFormHeaderPartial: (data) ->
    @formHeader.updatePartial @generateFormHeaderPartial data


  getRouteWithEntryPoint:(route)->
    {entryPoint} = KD.config
    if entryPoint and entryPoint.slug isnt KD.defaultSlug
      return "/#{entryPoint.slug}/#{route}"
    else
      return "/#{route}"

  showError = (err)->
    if err.code and err.code is 403
      {name, nickname}  = err.data
      KD.getSingleton('appManager').tell 'Account', 'displayConfirmEmailModal', name, nickname

    else if err.message.length > 50
      new KDModalView
        title        : "Something is wrong!"
        width        : 500
        overlay      : yes
        cssClass     : "new-kdmodal"
        content      : "<div class='modalformline'>" + err.message + "</div>"
    else
      new KDNotificationView
        title   : err.message
        duration: 1000
