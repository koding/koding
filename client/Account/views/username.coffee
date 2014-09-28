class AccountEditUsername extends JView

  notify  = (msg)->
    new KDNotificationView
      title    : msg
      duration : 2000

  constructor:->

    super

    @account = KD.whoami()

    @avatar = new AvatarStaticView @getAvatarOptions(), @account

    # TODO Since avatar upload is dependent on oskite
    # these buttons are not appended to view, until a new
    # avatar upload implementation
    @uploadAvatarBtn  = new KDButtonView
      icon            : yes
      style           : 'solid medium green'
      cssClass        : 'upload-avatar'
      title           : 'Upload a photo'
      loader          : yes

    @uploadAvatarInput = new KDInputView
      type            : 'file'
      cssClass        : 'upload-input'
      change          : @bound 'uploadInputChange'
      attributes      :
        accept        : 'image/*'

    @useGravatarBtn  = new KDButtonView
      icon           : yes
      style          : 'solid medium gray'
      cssClass       : 'use-gravatar'
      title          : 'Use Gravatar'
      callback       : =>
        @account.modify "profile.avatar": ""

    @emailForm = new KDFormViewWithFields
      fields               :
        profileHeader      :
          itemClass        : KDHeaderView
          title            : 'Profile Info'
          cssClass         : 'section-header'
        firstName          :
          placeholder      : "firstname"
          name             : "firstName"
          cssClass         : "medium"
          label            : 'Name'
        lastName           :
          cssClass         : "medium"
          placeholder      : "lastname"
          name             : "lastName"
          label            : 'Last name'
        email              :
          cssClass         : "medium"
          placeholder      : "you@yourdomain.com"
          name             : "email"
          testPath         : "account-email-input"
          label            : 'Email'
        username           :
          cssClass         : "medium"
          placeholder      : "username"
          name             : "username"
          label            : 'Username'
          attributes       :
            readonly       : "#{not /^guest-/.test @account.profile.nickname}"
          testPath         : "account-username-input"
        passwordHeader     :
          itemClass        : KDHeaderView
          title            : 'Change Password'
          cssClass         : 'section-header'
        password           :
          cssClass         : "medium"
          placeholder      : "password"
          name             : "password"
          type             : "password"
          label            : 'Password'
        confirm            :
          cssClass         : "medium"
          placeholder      : "confirm password"
          name             : "confirmPassword"
          type             : "password"
          label            : 'Password (again)'
      buttons              :
        Save               :
          title            : 'Save Changes'
          type             : 'submit'
          cssClass         : 'profile-save-changes'
          style            : 'solid green medium'
          loader           : yes
      callback             : @bound 'update'

  uploadInputChange : ->
    @uploadAvatarBtn.showLoader()

    file          = @uploadAvatarInput.getElement().files[0]

    unless file
      @uploadAvatarBtn.hideLoader()
      return

    reader        = new FileReader

    reader.onload = (event) =>
      dataURL     = event.target.result
      [_, base64] = dataURL.split ","

      @uploadAvatar base64, =>
        @uploadAvatarBtn.hideLoader()

    reader.readAsDataURL file


  uploadAvatar: (avatarData, callback)->
    FSHelper.s3.upload "avatar.png", avatarData, "user", "", (err, url)=>
      resized = KD.utils.proxifyUrl url,
        crop: true, width: 300, height: 300

      @account.modify "profile.avatar": "#{url}?#{Date.now()}", callback

  update: (formData) ->

    {daisy} = Bongo
    {JUser} = KD.remote.api
    {email, password, confirmPassword, firstName, lastName, username} = formData

    profileUpdated = yes
    skipPasswordConfirmation = no
    queue = [
      =>
        # update firstname and lastname
        me = KD.whoami()
        {profile:{firstName:oldFirstName, lastName:oldLastName}} = me
        # do not do anything if current firstname and lastname is same
        return queue.next() if oldFirstName is firstName and oldLastName is lastName

        me.modify {
          "profile.firstName": firstName,
          "profile.lastName" : lastName
        }, (err)->
          return notify err.message  if err
          queue.next()
      =>
        # secondly change user email address
        JUser.changeEmail {email}, (err, result)=>
          # here we are simply discarding the email is same error
          # but do not forget to warn users about other errors
          if err
            return queue.next() if err.message is "EmailIsSameError"
            @emailForm.buttons.Save.hideLoader()
            return notify err.message

          options = {skipPasswordConfirmation, email}
          confirmCurrentPassword options, (err) ->
            if err
              notify err
              profileUpdated = false
              return queue.next()
            skipPasswordConfirmation = true
            new VerifyPINModal 'Update E-Mail', (pin)->
              KD.remote.api.JUser.changeEmail {email, pin}, (err)->
                if err
                  notify err.message
                  profileUpdated = false
                queue.next()
      =>
        # on third turn update password
        # check for password confirmation
        if password isnt confirmPassword
          notify "Passwords did not match"
          @emailForm.buttons.Save.hideLoader()
          return
        # if password is empty than discard operation
        if password is ""
          {token} = KD.utils.parseQuery()
          if token
            profileUpdated = no
            notify "You should set your password"
          return queue.next()

        JUser.fetchUser (err, user)=>
          if err
            notify "An error occured"
            return queue.next()

          skipPasswordConfirmation = true  if user.passwordStatus isnt "valid"
          confirmCurrentPassword {skipPasswordConfirmation}, (err) =>
            if err
              notify err
              profileUpdated = false
              return queue.next()
            JUser.changePassword password, (err,docs)=>
              @emailForm.inputs.password.setValue ""
              @emailForm.inputs.confirm.setValue ""
              if err
                return queue.next()  if err.message is "PasswordIsSame"
                return notify err.message
              return queue.next()
      =>
        # if everything is OK or didnt change, show profile updated modal
        notify "Your account information is updated." if profileUpdated
        @emailForm.buttons.Save.hideLoader()
    ]
    daisy queue

  confirmCurrentPassword = ({skipPasswordConfirmation, email}, callback) ->
    return callback null if skipPasswordConfirmation
    new VerifyPasswordModal "Confirm", (currentPassword) ->
      options = {password: currentPassword, email}
      KD.remote.api.JUser.verifyPassword options, (err, confirmed) ->
        return callback err.message  if err
        return callback "Current password cannot be confirmed" unless confirmed
        callback null

  viewAppended:->
    {JPasswordRecovery, JUser} = KD.remote.api
    {token} = KD.utils.parseQuery()
    if token
      JPasswordRecovery.validate token, (err, isValid)=>
        if err and err.short isnt 'redeemed_token'
          notify err.message
        else if isValid
          notify "Thanks for confirming your email address"

    KD.whoami().fetchEmailAndStatus (err, userInfo)=>
      @userInfo = userInfo

      super

      @putDefaults()


  putDefaults:->

    {email} = @userInfo
    {nickname, firstName, lastName} = @account.profile

    @emailForm.inputs.email.setDefaultValue Encoder.htmlDecode email
    @emailForm.inputs.username.setDefaultValue Encoder.htmlDecode nickname
    @emailForm.inputs.firstName.setDefaultValue Encoder.htmlDecode firstName
    @emailForm.inputs.lastName.setDefaultValue Encoder.htmlDecode lastName

    {focus} = KD.utils.parseQuery()
    @emailForm.inputs[focus]?.setFocus()  if focus

    notify = (message)->
      new KDNotificationView
        title    : message
        duration : 3500

    if @userInfo.status is "unconfirmed"
      o =
        tagName      : "a"
        partial      : "You didn't verify your email yet <span>Verify now</span>"
        cssClass     : "action-link verify-email"
        testPath     : "account-email-edit"
        click        : =>
          KD.whoami().fetchFromUser "email", (err, email)=>
            return notify err.message if err

            KD.remote.api.JPasswordRecovery.resendVerification nickname, (err)=>
              @verifyEmail.hide()
              return KD.showError err if err
              notify "We've sent you a confirmation mail."

    @addSubView @verifyEmail = new KDCustomHTMLView o


  getAvatarOptions:->
    tagName       : 'figure'
    size          :
      width       : 150
      height      : 150

  pistachio:->

    """
    <div class='account-avatar-area clearfix'>
      {{> @avatar}}
      <section>
        {{> @emailForm}}
      </section>
    </div>
    """
