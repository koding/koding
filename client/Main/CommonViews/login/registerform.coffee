class RegisterInlineForm extends LoginViewInlineForm

  EMAIL_VALID    = no
  USERNAME_VALID = no
  ENTER          = 13

  constructor:(options={},data)->
    super options, data

    @email = new LoginInputViewWithLoader
      inputOptions    :
        name          : "email"
        placeholder   : "email address"
        testPath      : "register-form-email"
        validate      : @getEmailValidator()
        decorateValidation: no
        focus         : => @email.icon.unsetTooltip()
        keyup         : (event)   => @submitForm event  if event.which is ENTER



    @username?.destroy()
    @username = new LoginInputViewWithLoader
      inputOptions       :
        name             : "username"
        forceCase        : "lowercase"
        placeholder      : "username"
        testPath         : "register-form-username"
        focus            : => @username.icon.unsetTooltip()
        keyup            : (event) =>

          if (val = @username.input.getValue()).trim() isnt ''
            @domain.updatePartial "#{val}.koding.io"
          else
            @domain.updatePartial "username.koding.io"

          @submitForm event  if event.which is ENTER

        validate         :
          container      : this
          rules          :
            required     : yes
            rangeLength  : [4, 25]
            regExp       : /^[a-z\d]+([-][a-z\d]+)*$/i
            usernameCheck: (input, event)=> @usernameCheck input, event
            finalCheck   : (input, event)=> @usernameCheck input, event, 0
          messages       :
            required     : 'Please enter a username.'
            regExp       : 'Your desired username can only have lowercase letters and numbers.'
            rangeLength  : 'Username should be between 4 and 25 characters!'
          events         :
            required     : 'blur'
            rangeLength  : 'blur'
            regExp       : 'keyup'
            usernameCheck: 'keyup'
            finalCheck   : 'blur'
        decorateValidation: no

    {buttonTitle} = @getOptions()

    @button?.destroy()
    @button = new KDButtonView
      title         : buttonTitle or 'Create account'
      type          : 'button'
      style         : 'solid green medium'
      loader        : yes
      callback      : @bound 'submitForm'




    @invitationCode = new LoginInputView
      cssClass      : 'hidden'
      inputOptions  :
        name        : 'inviteCode'
        type        : 'hidden'

    @domain = new KDCustomHTMLView
      tagName : 'strong'
      partial : 'username.koding.io'

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

    KD.utils.killWait usernameCheckTimer
    input.setValidationResult "usernameCheck", null
    name = input.getValue()

    if input.valid
      usernameCheckTimer = KD.utils.wait delay, =>
        # @username.loader.show()
        KD.remote.api.JUser.usernameAvailable name, (err, response) =>
          # @username.loader.hide()
          {kodingUser, forbidden} = response
          if err
            if response?.kodingUser
              input.setValidationResult "usernameCheck", "Sorry, \"#{name}\" is already taken!"
              USERNAME_VALID = no
          else
            if forbidden
              input.setValidationResult "usernameCheck", "Sorry, \"#{name}\" is forbidden to use!"
              USERNAME_VALID = no
            else if kodingUser
              input.setValidationResult "usernameCheck", "Sorry, \"#{name}\" is already taken!"
              USERNAME_VALID = no
            else
              input.setValidationResult "usernameCheck", null
              USERNAME_VALID = yes


  getEmailValidator: ->
    container   : this
    event       : 'blur'
    rules       :
      required  : yes
      email     : yes
      available : (input, event) =>
        return if event?.which is 9
        input.setValidationResult 'available', null
        email = input.getValue()
        if input.valid
          # @email.loader.show()
          KD.remote.api.JUser.emailAvailable email, (err, response)=>
            # @email.loader.hide()
            if err then warn err
            else
              if response
                input.setValidationResult 'available', null
                EMAIL_VALID = yes
              else
                input.setValidationResult 'available', "Sorry, \"#{email}\" is already in use!"
                EMAIL_VALID = no
        return
    messages    :
      required  : 'Please enter your email address.'
      email     : 'That does not seem to be a valid email address.'


  submitForm: (event) ->

    # KDInputView doesn't give clear results with
    # async results that's why we maintain those
    # results manually in EMAIL_VALID and USERNAME_VALID
    # at least for now - SY
    if EMAIL_VALID and USERNAME_VALID and @username.input.valid and @email.input.valid
      @submit event
      return yes
    else
      @button.hideLoader()
      @username.input.validate()
      @email.input.validate()
      return no


  viewAppended:->

    super

    KD.getSingleton('mainController').on 'InvitationReceived', (invite)=>
      @$('.invitation-field').addClass('hidden')
      @$('.invited-by').removeClass('hidden')
      {origin} = invite
      @invitationCode.input.setValue invite.code
      @email.input.setValue invite.email
      @email.placeholder.setClass "out"
      if origin.constructorName is 'JAccount'# instanceof KD.remote.api.JAccount
        KD.remote.cacheable [origin], (err, [account])=>
          @addSubView new AvatarStaticView({size: width : 30, height : 30}, account), '.invited-by .wrapper'
          @addSubView new ProfileTextView({}, account), '.invited-by .wrapper'
      else
        @$('.invited-by').addClass('hidden')

  pistachio:->
    """
    <section class='main-part'>
      <div class='email'>{{> @email}}</div>
      <div class='username'>{{> @username}}</div>
      <div class='invitation-field invited-by hidden'>
        <span class='icon'></span>
        Invited by:
        <span class='wrapper'></span>
      </div>
      <div class='hint'>Usernames must be a minimum of 4 characters as they are also going to be used to set your Koding hostname, e.g. {{> @domain}}</div>
      <div>{{> @button}}</div>
      <div class="accept-tos">
      By creating an account, you accept Koding's <a href="/tos.html" target="_blank"> Terms of Service</a> and <a href="/privacy.html" target="_blank">Privacy Policy.</a>
      </div>
    </section>
    {{> @invitationCode}}
    """
      # <div>{{> @fullName}}</div>
    #   <div>{{> @password}}</div>
    #   <div>{{> @passwordConfirm}}</div>
