class RegisterInlineForm extends LoginViewInlineForm
  constructor:->
    super
    @firstName = new LoginInputView
      # cssClass        : "half-size"
      inputOptions    :
        name          : "firstName"
        placeholder   : "Your first name"
        validate      :
          event       : "blur"
          rules       :
            required  : yes
          messages    :
            required  : "Please enter your first name."

    @lastName = new LoginInputView
      # cssClass        : "half-size"
      inputOptions    :
        name          : "lastName"
        placeholder   : "Your last name"
        validate      :
          event       : "blur"
          rules       :
            required  : yes
          messages    :
            required  : "Please enter your last name."

    @email = new LoginInputView
      inputOptions    :
        name          : "email"
        placeholder   : "Your email address"
        validate      :
          event       : "blur"
          rules       :
            required  : yes
            email     : yes
          messages    :
            required  : "Please enter your email address."
            email     : "That doesn't seem like a valid email address."
        blur          : (input, event)=>
          @utils.nextTick =>
            @userAvatarFeedback input
    
    @avatar = new AvatarStaticView
      size        :
        width     : 60
        height    : 60
    , profile     : 
        hash      : md5.digest "there is no such email"
        firstName : "New koding user"


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
            minLength : 8
          messages    :
            minLength : "Password is required and should at least be 8 characters."

    @passwordConfirm = new LoginInputView
      inputOptions    :
        name          : "passwordConfirm"
        type          : "password"
        placeholder   : "Confirm your password"
        validate      :
          event       : "blur"
          rules       :
            match     : @password.input
          messages    :
            match     : "Password confirmation doesn't match!"

    @button = new KDButtonView
      title         : "REGISTER"
      type          : 'submit'
      style         : "koding-orange"
      loader        :
        color       : "#ffffff"
        diameter    : 21
    
    @invitationCode = new LoginInputView
      cssClass        : "half-size"
      inputOptions    :
        name          : "inviteCode"
        forceCase     : "lowercase"
        placeholder   : "your code..."
        # defaultValue  : "futureinsights"
        validate      :
          event       : "blur"
          rules       :
            required  : yes
          messages    :
            required  : "Please enter your invitation code."


  usernameCheckTimer = null

  usernameCheck:(input, event)->

    clearTimeout usernameCheckTimer
    input.setValidationResult "usernameCheck", null

    if input.valid
      usernameCheckTimer = setTimeout =>
        @username.loader.show()
        setTimeout =>
          @username.loader.hide()
          if event.which is 91
            input.setValidationResult "usernameCheck", "Sorry, \"#{input.inputGetValue()}\" is already taken!"
            @hideOldUserFeedback()
          else if event.which is 18
            @showOldUserFeedback()
          else
            @hideOldUserFeedback()
            input.setValidationResult "usernameCheck", null
        ,1000
      ,800
    else
      @hideOldUserFeedback()

    return

  showOldUserFeedback:->
    
    @username.setClass "kodingen"
    @passwordConfirm.$().slideUp 100
    @$('p.kodingen-user-notification b').text "#{@username.input.inputGetValue()}"
    @$('p.kodingen-user-notification').slideDown 100

  hideOldUserFeedback:->
    
    @username.unsetClass "kodingen"
    @$('p.kodingen-user-notification').slideUp 100
    @passwordConfirm.$().slideDown 100

  userAvatarFeedback:(input)->

    if input.valid
      @avatar.setData 
        profile     : 
          hash      : md5.digest input.inputGetValue()
          firstName : "New koding user"
      @avatar.render()

  viewAppended:()->

    super
    KD.getSingleton('mainController').registerListener
      KDEventTypes  : 'InvitationReceived'
      listener      : @
      callback      : (pubInst, invite)=>
        @$('.invitation-field').addClass('hidden')
        @$('.invited-by').removeClass('hidden')
        {origin} = invite
        @invitationCode.input.inputSetValue invite.code
        @email.input.inputSetValue invite.inviteeEmail
        if origin instanceof bongo.api.JAccount
          @addSubView new AvatarStaticView({size: width : 30, height : 30}, origin), '.invited-by .wrapper'
          @addSubView new ProfileTextView({}, origin), '.invited-by .wrapper'
        else
          @$('.invited-by').addClass('hidden')

  pistachio:->
    """
    <div>
      {{> @avatar}}
      <section class='right-overflow'>
        {{> @firstName}}
        {{> @lastName}}
      </section>
    </div>
    <div>{{> @email}}</div>
    <div>{{> @username}}</div>
    <div>{{> @password}}</div>
    <div>
      {{> @passwordConfirm}}
      <p class='kodingen-user-notification' style='display:none'>
        <b>This</b> is a Kodingen username, if you own this 
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
    """
