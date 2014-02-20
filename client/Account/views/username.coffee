class AccountEditUsername extends JView

  notify  = (msg)->
    new KDNotificationView
      title    : msg
      duration : 2000

  constructor:->

    super

    @account = KD.whoami()

    @avatar = new AvatarStaticView @getAvatarOptions(), @account

    @emailForm = new KDFormViewWithFields
      fields               :
        firstName          :
          placeholder      : "firstname"
          name             : "firstName"
          cssClass         : "thin half"
          nextElement      :
            lastName       :
              cssClass     : "thin half"
              placeholder  : "lastname"
              name         : "lastName"
        email              :
          cssClass         : "thin"
          placeholder      : "you@yourdomain.com"
          name             : "email"
          testPath         : "account-email-input"
        username           :
          cssClass         : "thin"
          placeholder      : "username"
          name             : "username"
          attributes       :
            readonly       : "#{not /^guest-/.test @account.profile.nickname}"
          testPath         : "account-username-input"
        password           :
          cssClass         : "thin half"
          placeholder      : "password"
          name             : "password"
          type             : "password"
          nextElement      :
            confirm        :
              cssClass     : "thin half"
              placeholder  : "confirm password"
              name         : "confirmPassword"
              type         : "password"
      buttons              :
        Save               :
          title            : 'SAVE CHANGES'
          type             : 'submit'
          cssClass         : 'profile-save-changes'
          style            : 'solid green'
      callback             : @bound 'update'


  update:(formData)->

    {daisy} = Bongo
    {JUser} = KD.remote.api
    {email, password, confirmPassword, firstName, lastName, username} = formData

    profileUpdated = yes
    currentPasswordConfirmed = no
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
            return notify err.message

          confirmCurrentPassword currentPasswordConfirmed, =>
            currentPasswordConfirmed = true
            new VerifyPINModal 'Update E-Mail', (pin)=>
              KD.remote.api.JUser.changeEmail {email, pin}, (err)=>
                if err
                  notify err.message
                  profileUpdated = false
                queue.next()
      =>
        # on third turn update password
        # check for password confirmation
        return  notify "Passwords did not match" if password isnt confirmPassword
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
          else
            currentPasswordConfirmed = true unless user.passwordStatus is "valid"
            confirmCurrentPassword currentPasswordConfirmed, =>
              JUser.changePassword password, (err,docs)=>
                @emailForm.inputs.password.setValue ""
                @emailForm.inputs.confirm.setValue ""
                if err
                  return queue.next()  if err.message is "PasswordIsSame"
                  return  notify err.message
                return queue.next()
      =>
        # if everything is OK or didnt change, show profile updated modal
        notify "Your account information is updated." if profileUpdated
    ]
    daisy queue

  confirmCurrentPassword = (currentPasswordConfirmed, callback) ->
    return callback null if currentPasswordConfirmed
    new VerifyPasswordModal "Confirm", (currentPassword) ->
      KD.remote.api.JUser.verifyPassword currentPassword, (err, confirmed) ->
        return notify err.message if err
        return notify "Current password cannot be confirmed" unless confirmed
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

    @emailForm.inputs.email.setDefaultValue email
    @emailForm.inputs.username.setDefaultValue nickname
    @emailForm.inputs.firstName.setDefaultValue firstName
    @emailForm.inputs.lastName.setDefaultValue lastName

    {focus} = KD.utils.parseQuery()
    @emailForm.inputs[focus]?.setFocus()  if focus

    if @userInfo.status is "unconfirmed"
      o =
        tagName      : "a"
        partial      : "You didn't verify your email yet <span>Verify now</span>"
        cssClass     : "action-link verify-email"
        testPath     : "account-email-edit"
        click        : =>
          KD.remote.api.JPasswordRecovery.recoverPassword @account.profile.nickname, (err)=>
            message = "Email confirmation mail is sent"
            if err then message = err.message else @verifyEmail.hide()

            new KDNotificationView
              title    : message
              duration : 3500

    @addSubView @verifyEmail = new KDCustomHTMLView o


  getAvatarOptions:->

    showStatus    : yes
    tooltip       :
      title       : "<p class='centertext'>Click avatar to edit</p>"
      placement   : "below"
      arrow       : placement : "top"
    size          :
      width       : 160
      height      : 160
    click         : =>
      KD.singleton('appManager').require 'Activity', =>
        pos =
          top  : @avatar.getY() - 8
          left : @avatar.getX() - 8

        @avatarMenu?.destroy()
        @avatarMenu = new JContextMenu
          menuWidth  : 312
          cssClass   : "avatar-menu dark"
          delegate   : @avatar
          x          : @avatar.getX() + 96
          y          : @avatar.getY() - 7
        , customView : @avatarChange = new AvatarChangeView delegate: this, @account

        @avatarChange.on "UseGravatar", => @account.modify "profile.avatar" : ""

        @avatarChange.on "UsePhoto", (dataURI)=>
          [_, avatarBase64] = dataURI.split ","
          @avatar.setAvatar "url(#{dataURI})"
          @avatar.$().css
            backgroundSize: "auto 90px"
          @avatarChange.emit "LoadingStart"
          @uploadAvatar avatarBase64, =>
            @avatarChange.emit "LoadingEnd"

  uploadAvatar: (avatarData, callback)->
    FSHelper.s3.upload "avatar.png", avatarData, "user", "", (err, url)=>
      resized = KD.utils.proxifyUrl url,
        crop: true, width: 300, height: 300

      @account.modify "profile.avatar": "#{url}?#{Date.now()}", callback

  pistachio:->

    """
    {{> @avatar}}
    <section>
      {{> @emailForm}}
    </section>
    """

