class RegisterInlineForm extends LoginViewInlineForm

  constructor:(options={},data)->
    super options, data

    # random = KD.utils.getRandomNumber()

    @email = new LoginInputViewWithLoader
      inputOptions    :
        name          : "email"
        placeholder   : "email address"
        # defaultValue  : "gokmen+#{random}@goksel.me"
        testPath      : "register-form-email"
        validate      : @getEmailValidator()
        decorateValidation: no

    @avatar = new AvatarStaticView
      size        :
        width     : 55
        height    : 55
    , profile     :
        hash      : md5.digest "there is no such email"
        firstName : "New koding user"
    @avatar.hide()

    @username = new LoginInputViewWithLoader
      inputOptions       :
        name             : "username"
        forceCase        : "lowercase"
        placeholder      : "username"
        # defaultValue     : "gokmen-#{random}"
        testPath         : "register-form-username"
        keyup            : =>

          if (val = @username.input.getValue()).trim() isnt ''
            @domain.updatePartial "#{val}.kd.io"
          else
            @domain.updatePartial "username.kd.io"

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
            rangeLength  : "keyup"
            regExp       : "keyup"
            usernameCheck: "keyup"
            finalCheck   : "blur"
        decorateValidation: no

    @button = new KDButtonView
      title         : "Create account"
      type          : 'submit'
      style         : "solid green medium"
      loader        : yes

    @invitationCode = new LoginInputView
      cssClass      : "hidden"
      inputOptions  :
        name        : "inviteCode"
        type        : 'hidden'

    @domain = new KDCustomHTMLView
      tagName : 'strong'
      partial : 'username.kd.io'

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

  userAvatarFeedback:(input)->
    if input.valid
      @avatar.setData
        profile     :
          hash      : md5.digest input.getValue()
          firstName : "New koding user"
      @avatar.render()
      @showUserAvatar()
    else
      @hideUserAvatar()

  showUserAvatar:-> @avatar.show()

  hideUserAvatar:-> @avatar.hide()

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

  pistachio:->
    """
    <section class='main-part'>
      <div class='email'>{{> @avatar}}{{> @email}}</div>
      <div class='username'>{{> @username}}</div>
      <div class='invitation-field invited-by hidden'>
        <span class='icon'></span>
        Invited by:
        <span class='wrapper'></span>
      </div>
      <div class='hint'>Your username must be at least 4 characters and it’s also going to be your {{> @domain}} domain.</div>
      <div>{{> @button}}</div>
      <div class="accept-tos">
      By creating an account, I accept Koding's <a href="/tos.html" target="_blank"> Terms of Service</a> and <a href="/privacy.html" target="_blank">Privacy Policy.</a>
      </div>
    </section>
    {{> @invitationCode}}
    """
      # <div>{{> @fullName}}</div>
    #   <div>{{> @password}}</div>
    #   <div>{{> @passwordConfirm}}</div>
