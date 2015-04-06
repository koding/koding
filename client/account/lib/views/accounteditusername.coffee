kd = require 'kd'
KDButtonView = kd.ButtonView
KDCustomHTMLView = kd.CustomHTMLView
KDFormViewWithFields = kd.FormViewWithFields
KDHeaderView = kd.HeaderView
KDInputView = kd.InputView
KDNotificationView = kd.NotificationView
remote = require('app/remote').getInstance()
s3upload = require 'app/util/s3upload'
whoami = require 'app/util/whoami'
showError = require 'app/util/showError'
JView = require 'app/jview'
AvatarStaticView = require 'app/commonviews/avatarviews/avatarstaticview'
Encoder = require 'htmlencode'
VerifyPINModal = require 'app/commonviews/verifypinmodal'
VerifyPasswordModal = require 'app/commonviews/verifypasswordmodal'
sinkrow = require 'sinkrow'
KodingSwitch = require 'app/commonviews/kodingswitch'


module.exports = class AccountEditUsername extends JView

  notify = (msg, duration = 2000) ->
    new KDNotificationView
      title    : msg
      duration : duration


  constructor: (options = {}, data) ->

    super options, data
    @initViews()


  initViews: ->

    @account = whoami()

    @avatar = new AvatarStaticView @getAvatarOptions(), @account

    @uploadAvatarBtn  = new KDButtonView
      style           : 'solid small green'
      cssClass        : 'upload-avatar'
      title           : 'Upload Image'
      loader          : yes

    @uploadAvatarInput = new KDInputView
      type            : 'file'
      cssClass        : 'AppModal--account-avatarArea-buttons-upload'
      change          : @bound 'uploadInputChange'
      attributes      :
        accept        : 'image/*'

    @useGravatarBtn  = new KDButtonView
      style          : 'solid small gray'
      cssClass       : 'use-gravatar'
      title          : 'Use Gravatar'
      callback       : =>
        @account.modify "profile.avatar": ""

    @emailForm = new KDFormViewWithFields
      cssClass             : 'AppModal-form'
      fields               :
        firstName          :
          cssClass         : 'Formline--half'
          placeholder      : "firstname"
          name             : "firstName"
          label            : 'Name'
        lastName           :
          cssClass         : 'Formline--half'
          placeholder      : "lastname"
          name             : "lastName"
          label            : 'Last name'
        email              :
          cssClass         : 'Formline--half'
          placeholder      : "you@yourdomain.com"
          name             : "email"
          testPath         : "account-email-input"
          label            : 'Email'
        username           :
          cssClass         : 'Formline--half'
          placeholder      : "username"
          name             : "username"
          label            : 'Username'
          attributes       :
            readonly       : "#{not /^guest-/.test @account.profile.nickname}"
          testPath         : "account-username-input"
        passwordHeader     :
          itemClass        : KDCustomHTMLView
          partial          : 'CHANGE PASSWORD'
          cssClass         : 'AppModal-form-sectionHeader'
        password           :
          cssClass         : 'Formline--half'
          placeholder      : "password"
          name             : "password"
          type             : "password"
          label            : 'Password'
        confirm            :
          cssClass         : 'Formline--half'
          placeholder      : "confirm password"
          name             : "confirmPassword"
          type             : "password"
          label            : 'Password (again)'
        shareLocation      :
          label            : 'Share my location while posting'
          defaultValue     : whoami().shareLocation
          itemClass        : KodingSwitch
          cssClass         : 'tiny'
          name             : 'shareLocation'
      buttons              :
        Save               :
          title            : 'Save Changes'
          type             : 'submit'
          style            : 'solid green small'
          loader           : yes
      callback             : @bound 'update'


  uploadInputChange: ->

    @uploadAvatarBtn.showLoader()

    file = @uploadAvatarInput.getElement().files[0]

    return @uploadAvatarBtn.hideLoader()  unless file

    mimeType      = file.type
    reader        = new FileReader
    reader.onload = (event) =>
      dataURL     = event.target.result
      [_, base64] = dataURL.split ","

      @uploadAvatar
        mimeType : mimeType
        content  : file
      , =>
        @uploadAvatarBtn.hideLoader()

    reader.readAsDataURL file


  uploadAvatar: (avatar, callback) ->

    {mimeType, content} = avatar

    s3upload
      name    : "avatar-#{Date.now()}"
      content : content
      mimeType: mimeType
      timeout : 30000
    , (err, url) =>

      @uploadAvatarBtn.hideLoader()

      return showError err  if err

      @account.modify "profile.avatar": "#{url}"


  update: (formData) ->

    {JUser} = remote.api
    {email, password, confirmPassword, firstName, lastName, username, shareLocation} = formData
    profileUpdated = yes
    skipPasswordConfirmation = no
    queue = [
      =>
        # update firstname and lastname
        me = whoami()

        me.modify {
          "profile.firstName": firstName,
          "profile.lastName" : lastName
          "shareLocation"    : formData.shareLocation
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
              remote.api.JUser.changeEmail {email, pin}, (err)->
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
          {token} = kd.utils.parseQuery()
          if token
            profileUpdated = no
            notify "You should set your password"
          return queue.next()

        JUser.fetchUser (err, user)=>
          if err
            notify "An error occurred"
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
    sinkrow.daisy queue


  confirmCurrentPassword = (opts, callback) ->

    {skipPasswordConfirmation, email} = opts

    return callback null  if skipPasswordConfirmation

    new VerifyPasswordModal 'Confirm', (currentPassword) ->
      options = {password: currentPassword, email}
      remote.api.JUser.verifyPassword options, (err, confirmed) ->

        return callback err.message  if err
        return callback 'Current password cannot be confirmed'  unless confirmed

        callback null


  viewAppended: ->

    {JPasswordRecovery, JUser} = remote.api
    {token} = kd.utils.parseQuery()
    if token
      JPasswordRecovery.validate token, (err, isValid)=>
        if err and err.short isnt 'redeemed_token'
          notify err.message
        else if isValid
          notify "Thanks for confirming your email address"

    kd.singletons.mainController.ready =>
      whoami().fetchEmailAndStatus (err, userInfo) =>

        return kd.warn err  if err

        @userInfo = userInfo

        super

        @putDefaults()


  putDefaults: ->

    {email} = @userInfo
    {nickname, firstName, lastName} = @account.profile

    @emailForm.inputs.email.setDefaultValue Encoder.htmlDecode email
    @emailForm.inputs.username.setDefaultValue Encoder.htmlDecode nickname
    @emailForm.inputs.firstName.setDefaultValue Encoder.htmlDecode firstName
    @emailForm.inputs.lastName.setDefaultValue Encoder.htmlDecode lastName
    @emailForm.inputs.shareLocation.setDefaultValue whoami().shareLocation

    {focus} = kd.utils.parseQuery()
    @emailForm.inputs[focus]?.setFocus()  if focus

    notify = (message)->
      new KDNotificationView
        title    : message
        duration : 3500

    if @userInfo.status is "unconfirmed"
      opts =
        tagName      : "a"
        partial      : "You didn't verify your email yet <span>Verify now</span>"
        cssClass     : "action-link verify-email"
        testPath     : "account-email-edit"
        click        : =>
          whoami().fetchFromUser "email", (err, email) =>
            return notify err.message, 3500  if err

            remote.api.JPasswordRecovery.resendVerification nickname, (err) =>
              @verifyEmail.hide()
              return showError err if err
              notify "We've sent you a confirmation mail.", 3500

    @addSubView @verifyEmail = new KDCustomHTMLView opts


  getAvatarOptions: ->
    tagName       : 'figure'
    cssClass      : 'AppModal--account-avatar'
    size          :
      width       : 95
      height      : 95


  pistachio: ->
    """
    <div class='AppModal--account-avatarArea clearfix'>
      {{> @avatar}}
      <div class="AppModal--account-avatarArea-buttons">
        {{> @uploadAvatarBtn}}
        {{> @uploadAvatarInput}}
        {{> @useGravatarBtn}}
      </div>
    </div>
    {{> @emailForm}}
    """



