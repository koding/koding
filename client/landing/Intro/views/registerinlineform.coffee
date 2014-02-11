class HomeRegisterForm extends KDFormView

  constructor:(options={},data)->

    super options, data

    @email = new HomeLoginInput
      inputOptions    :
        name          : "email"
        placeholder   : 'your@email.com'
        testPath      : "register-form-email"
        validate      : @getEmailValidator()

    @username = new HomeLoginInput
      inputOptions       :
        name             : "username"
        forceCase        : "lowercase"
        placeholder      : 'desired username'
        testPath         : "register-form-username"

        validate         :
          container      : this
          rules          :
            required     : yes
            rangeLength  : [4,25]
            regExp       : /^[a-z\d]+([-][a-z\d]+)*$/i
            usernameCheck: (input, event)=> @usernameCheck input, event
            finalCheck   : (input, event)=> @usernameCheck input, event, 0
          messages       :
            required     : "Please enter a username."
            regExp       : "For username only lowercase letters and numbers are allowed!"
            rangeLength  : "Username should be between 4 and 25 characters!"
          events         :
            required     : "blur"
            rangeLength  : "blur"
            regExp       : "keyup"
            usernameCheck: "keyup"
            finalCheck   : "blur"

    @button = new KDButtonView
      title         : 'Sign up'
      cssClass      : 'solid red shadowed'
      type          : 'submit'
      callback      : =>
        if @username.input.getValue() is ""
          @username.showError "Please enter a username."
        if @email.input.getValue() is ""
          @email.showError "Please enter an email."



    @on "SubmitFailed", (msg)=>
      # if msg is "Wrong password"
      #   @passwordConfirm.input.setValue ''
      #   @password.input.setValue ''
      #   @password.input.validate()

      @button.hideLoader()

  usernameCheckTimer = null

  reset:->
    inputs = KDFormView.findChildInputs this
    input.clearValidationFeedback() for input in inputs
    super

  usernameCheck:(input, event, delay=800)->
    return if event?.which is 9
    return if input.getValue().length < 4
    clearTimeout usernameCheckTimer
    input.setValidationResult "usernameCheck", null
    name = input.getValue()

    if input.valid
      usernameCheckTimer = setTimeout =>
        @username.loader.show()
        KD.remote.api.JUser.usernameAvailable name, (err, response)=>
          @username.loader.hide()
          {kodingUser, forbidden} = response
          if err
            if response?.kodingUser
              input.setValidationResult "usernameCheck", "Sorry, \"#{name}\" is already taken!"
          else
            if forbidden
              input.setValidationResult "usernameCheck", "Sorry, \"#{name}\" is forbidden to use!"
            else if kodingUser
              input.setValidationResult "usernameCheck", "Sorry, \"#{name}\" is already taken!"
            else
              input.setValidationResult "usernameCheck", null
      , delay

  getEmailValidator: ->
    container   : this
    event       : "blur"
    rules       :
      required  : yes
      email     : yes
      available : (input, event)=>
        return if event?.which is 9
        input.setValidationResult "available", null
        email = input.getValue()
        if input.valid
          @email.loader.show()
          KD.remote.api.JUser.emailAvailable email, (err, response)=>
            @email.loader.hide()
            if err then warn err
            else
              if response
                input.setValidationResult "available", null
              else
                input.setValidationResult "available", "Sorry, \"#{email}\" is already in use!"
        return
    messages    :
      required  : "Please enter your email address."
      email     : "That doesn't seem like a valid email address."

  doRegister:(formData)->
    (KD.getSingleton 'mainController').isLoggingIn on
    formData.agree = 'on'
    formData.referrer = $.cookie 'referrer'
    # we need to close the group channel so we don't receive the cycleChannel event.
    # getting the cycleChannel even for our own MemberAdded can cause a race condition
    # that'll leak a guest account.
    KD.getSingleton('groupsController').groupChannel?.close()

    KD.remote.api.JUser.convert formData, (err, replacementToken)=>
      account = KD.whoami()
      @button.hideLoader()

      if err
        {message} = err
        warn "An error occured while registering:", err
        @emit "SubmitFailed", message

      else
        KD.mixpanel.alias account.profile.nickname
        KD.mixpanel "Signup, success"

        try
          mixpanel.track "Alternate Signup, success"
        catch
          KD.logToExternal "mixpanel doesn't exist"

        _gaq.push ['_trackEvent', 'Sign-up']

        $.cookie 'newRegister', yes
        $.cookie 'clientId', replacementToken
        KD.getSingleton('mainController').accountChanged account

        new KDNotificationView
          cssClass  : "login"
          title     : '<span></span>Good to go, Enjoy!'
          # content   : 'Successfully registered!'
          duration  : 2000

        firstRoute = KD.getSingleton("router").visitedRoutes.first
        if firstRoute and /^\/(?:Reset|Register|Confirm|R)\//.test firstRoute
          firstRoute = "/Activity"

        {entryPoint} = KD.config
        KD.getSingleton('router').handleRoute firstRoute or '/Activity', {replaceState: yes, entryPoint}

        KD.utils.wait 1000, =>
          @reset()
          @button.hideLoader()
          @hide()


  viewAppended: JView::viewAppended

  pistachio:->
    """
    {{> @email}}
    {{> @username}}
    {{> @button}}
    """
