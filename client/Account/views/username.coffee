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
          attributes       : readonly : "true"
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
          style            : 'solid green fr'
      callback             : @bound 'update'

  update:(formData)->

    {email} = formData

    # fixme: if new pass inputs filled do change password
    # CHANGE PASSWORD
    # KD.remote.api.JUser.changePassword formData.password,(err,docs)=>
    #   unless err then do @passwordDidUpdate

    # CHANGE EMAIL

    KD.remote.api.JUser.changeEmail {email}, (err, result)=>

      return notify err.message  if err and err.name isnt 'PINExistsError'

      notify err.message  if err and err.name is 'PINExistsError'

      new VerifyPINModal 'Update E-Mail', (pin)=>
        KD.remote.api.JUser.changeEmail {email, pin}, (err)=>
          notify if err then err.message else "E-mail changed!"
          @emit "EmailChangedSuccessfully", email


  viewAppended:->

    KD.remote.api.JUser.fetchUser (err,user)=>

      @user    = user

      super

      @putDefaults()


  putDefaults:->

    {email} = @user
    {nickname, firstName, lastName} = @account.profile

    @emailForm.inputs.email.setDefaultValue email
    @emailForm.inputs.username.setDefaultValue nickname
    @emailForm.inputs.firstName.setDefaultValue firstName
    @emailForm.inputs.lastName.setDefaultValue lastName

    if @user.status is "unconfirmed"
      o =
        tagName      : "a"
        partial      : "You didn't verify your email yet <span>Verify now</span>"
        cssClass     : "action-link verify-email"
        testPath     : "account-email-edit"
        click        : =>
          KD.remote.api.JEmailConfirmation.resetToken @account.profile.nickname, (err)=>

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
      KD.singleton('appManager').create 'Activity', =>
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

  pistachio:->

    """
    {{> @avatar}}
    <section>
      {{> @emailForm}}
    </section>
    """

