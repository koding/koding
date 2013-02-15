###
  todo:
###

class RegisterInlineForm extends LoginViewInlineForm

  constructor:->

    super
    @firstName = new LoginInputView
      cssClass        : "half-size"
      inputOptions    :
        # defaultValue  : "xx"
        name          : "firstName"
        placeholder   : "Your first name"
        validate      :
          event       : "blur"
          rules       :
            required  : yes
          messages    :
            required  : "Please enter your first name."

    @lastName = new LoginInputView
      cssClass        : "half-size"
      inputOptions    :
        name          : "lastName"
        # defaultValue  : "xx"
        placeholder   : "Your last name"
        validate      :
          event       : "blur"
          rules       :
            required  : yes
          messages    :
            required  : "Please enter your last name."

    @email = new LoginInputViewWithLoader
      inputOptions    :
        name          : "email"
        placeholder   : "Your email address"
        validate      :
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
                    @userAvatarFeedback input
              return
          messages    :
            required  : "Please enter your email address."
            email     : "That doesn't seem like a valid email address."
        blur          : (input, event)=>
          @utils.wait =>
            @userAvatarFeedback input

    @avatar = new AvatarStaticView
      size        :
        width     : 20
        height    : 20
    , profile     :
        hash      : md5.digest "there is no such email"
        firstName : "New koding user"
    @avatar.hide()

    @username = new LoginInputViewWithLoader
      inputOptions       :
        name             : "username"
        forceCase        : "lowercase"
        placeholder      : "Desired username"
        validate         :
          rules          :
            required     : yes
            rangeLength  : [4,25]
            regExp       : /^[a-z\d]+([-][a-z\d]+)*$/i
            usernameCheck: (input, event)=> @usernameCheck input, event
            finalCheck   : (input, event)=> @usernameCheck input, event
          messages       :
            required     : "Please enter a username."
            regExp       : "For username only lowercase letters and numbers are allowed!"
            rangeLength  : "Username should be minimum 4 maximum 25 chars!"
          events         :
            required     : "blur"
            rangeLength  : "keyup"
            regExp       : "keyup"
            usernameCheck: "keyup"
            finalCheck   : "blur"
        iconOptions      :
          tooltip        :
            placement    : "right"
            offset       : 2
            title        : """
                            Only lowercase letters and numbers are allowed,
                            max 25 characters. Also keep in mind that the username you select will
                            be a part of your kodingen domain, and can't be changed later.
                            i.e. http://username.kodingen.com <h1></h1>
                           """

    @password = new LoginInputView
      inputOptions    :
        name          : "password"
        type          : "password"
        placeholder   : "Create a password"
        validate      :
          event       : "blur"
          rules       :
            required  : yes
            minLength : 8
          messages    :
            required  : "Password is required."
            minLength : "Password should at least be 8 characters."
        change        : (event)=>
          if @kodingenUser
            @passwordConfirm.input.setValue @password.input.getValue()

    @passwordConfirm = new LoginInputView
      cssClass        : "password-confirm"
      inputOptions    :
        name          : "passwordConfirm"
        type          : "password"
        placeholder   : "Confirm your password"
        validate      :
          event       : "blur"
          rules       :
            required  : yes
            match     : @password.input
            minLength : 8
          messages    :
            required  : "Password confirmation required!"
            match     : "Password confirmation doesn't match!"
        focus         : (event)=>
          if @kodingenUser
            @passwordConfirm.input.setValue @password.input.getValue()
            @invitationCode.input.$().focus()


    @button = new KDButtonView
      title         : "REGISTER"
      type          : 'submit'
      style         : "koding-orange"
      loader        :
        color       : "#ffffff"
        diameter    : 21

    @disabledNotice = new KDCustomHTMLView
      tagName       : "section"
      cssClass      : "disabled-notice"
      partial       : """
                      <p>
                      <b>REGISTRATIONS ARE CURRENTLY DISABLED</b>
                      We're sorry for that, please follow us on <a href='http://twitter.com/koding' target='_blank'>twitter</a>
                      if you want to be notified when registrations are enabled again.
                      </p>
                      """

    @invitationCode = new LoginInputView
      cssClass        : "half-size"
      inputOptions    :
        name          : "inviteCode"
        forceCase     : "lowercase"
        placeholder   : "your code..."
        # defaultValue  : "111"
        validate      :
          event       : "blur"
          rules       :
            required  : yes
          messages    :
            required  : "Please enter your invitation code."

    @on "SubmitFailed", (msg)=>
      if msg is "Wrong password"
        @passwordConfirm.input.setValue ''
        @password.input.setValue ''
        @password.input.validate()

      @button.hideLoader()
      @invitationCode.notify msg


  usernameCheckTimer = null

  reset:->

    inputs = KDFormView.findChildInputs @
    input.clearValidationFeedback() for input in inputs
    super

  usernameCheck:(input, event)->

    return if event?.which is 9

    clearTimeout usernameCheckTimer
    input.setValidationResult "usernameCheck", null
    name = input.getValue()

    if input.valid
      usernameCheckTimer = setTimeout =>
        @username.loader.show()
        KD.remote.api.JUser.usernameAvailable name, (err, response)=>
          @username.loader.hide()
          {kodingUser, kodingenUser, forbidden} = response
          if err
            if response?.kodingUser
              input.setValidationResult "usernameCheck", "Sorry, \"#{name}\" is already taken!"
              @hideOldUserFeedback()
          else
            if forbidden
              input.setValidationResult "usernameCheck", "Sorry, \"#{name}\" is forbidden to use!"
              @hideOldUserFeedback()
            else if kodingenUser and forbidden
              input.setValidationResult "usernameCheck", "Sorry, \"#{name}\" is forbidden to use!"
              @hideOldUserFeedback()
            else if kodingUser and kodingenUser
              # log "contact support"
              input.setValidationResult "usernameCheck", "Sorry, \"#{name}\" is already taken!"
              @hideOldUserFeedback()
            else if kodingUser
              input.setValidationResult "usernameCheck", "Sorry, \"#{name}\" is already taken!"
              @hideOldUserFeedback()
            else if kodingenUser
              @showOldUserFeedback()
            else
              @hideOldUserFeedback()
              input.setValidationResult "usernameCheck", null
      ,800
    else
      @hideOldUserFeedback()
    return

  showOldUserFeedback:->

    @addCustomData "kodingenUser", "on"
    @kodingenUser = yes
    @parent.setClass "taller"
    @username.setClass "kodingen"
    @password.input.$().attr "placeholder", "Type your kodingen password"

    {validate} = @password.input.getOptions()
    delete validate.rules.minLength
    @password.input.setValidation validate
    @passwordConfirm.input.setValidation validate

    @passwordConfirm.setHeight 0
    @$('p.kodingen-user-notification b').text "#{@username.input.getValue()}"
    @$('p.kodingen-user-notification').height 54

  hideOldUserFeedback:->

    @removeCustomData "kodingenUser"
    @kodingenUser = no
    @parent.unsetClass "taller"
    @username.unsetClass "kodingen"
    @password.input.$().attr "placeholder", "Create a password"

    {validate} = @password.input.getOptions()
    validate.rules.minLength = 8
    @password.input.setValidation validate
    @passwordConfirm.input.setValidation validate

    @$('p.kodingen-user-notification').height 0
    @passwordConfirm.setHeight 32

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

  viewAppended:()->

    super

    KD.getSingleton('mainController').on 'InvitationReceived', (invite)=>
      @$('.invitation-field').addClass('hidden')
      @$('.invited-by').removeClass('hidden')
      {origin} = invite
      @invitationCode.input.setValue invite.code
      @email.input.setValue invite.inviteeEmail
      if origin.constructorName is 'JAccount'# instanceof KD.remote.api.JAccount
        KD.remote.cacheable [origin], (err, [account])=>
          @addSubView new AvatarStaticView({size: width : 30, height : 30}, account), '.invited-by .wrapper'
          @addSubView new ProfileTextView({}, account), '.invited-by .wrapper'
      else
        @$('.invited-by').addClass('hidden')

  pistachio:->

    """
    <div>{{> @firstName}}{{> @lastName}}</div>
    <div>{{> @email}}{{> @avatar}}</div>
    <div>{{> @username}}</div>
    <div>{{> @password}}</div>
    <div>
      {{> @passwordConfirm}}
      <p class='kodingen-user-notification'>
        <b>This</b> is a reserved Kodingen username, if you own this
        account please type your Kodingen password above to unlock your old
        username for the new Koding.
      </p>
    </div>
    <div class='invitation-field invited-by hidden'>
      <span class='icon'></span>
      Invited by:
      <span class='wrapper'></span>
    </div>
    <div class='invitation-field clearfix'>
      <span class='icon'></span>
      Invitation code:
      {{> @invitationCode}}
    </div>
    <div>{{> @button}}</div>
    {{> @disabledNotice}}
    """
