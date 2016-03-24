kd                   = require 'kd'
Encoder              = require 'htmlencode'
async                = require 'async'
remote               = require('app/remote').getInstance()
JView                = require 'app/jview'
s3upload             = require 'app/util/s3upload'
whoami               = require 'app/util/whoami'
showError            = require 'app/util/showError'
VerifyPINModal       = require 'app/commonviews/verifypinmodal'
VerifyPasswordModal  = require 'app/commonviews/verifypasswordmodal'
AvatarStaticView     = require 'app/commonviews/avatarviews/avatarstaticview'


notify = (title, duration = 2000) -> new kd.NotificationView { title, duration }


module.exports = class HomeAccountEditProfile extends kd.CustomHTMLView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    super options, data

    @account = whoami()

    @avatar = new AvatarStaticView @getAvatarOptions(), @account

    @uploadAvatarBtn  = new kd.ButtonView
      style    : 'solid small green'
      cssClass : 'upload-avatar'
      title    : 'Upload Image'
      loader   : yes

    @uploadAvatarInput = new kd.InputView
      type       : 'file'
      cssClass   : 'HomeAppView--account-avatarArea-buttons-upload'
      change     : @bound 'uploadInputChange'
      attributes :
        accept   : 'image/*'

    @useGravatarBtn  = new kd.ButtonView
      style    : 'solid small gray'
      cssClass : 'use-gravatar'
      title    : 'Use Gravatar'
      loader   : yes
      callback : =>
        @account.modify { 'profile.avatar' : '' }, (err) =>
          console.warn err  if err
          @useGravatarBtn.hideLoader()

    fields =
      accountHeader  :
        itemClass    : kd.CustomHTMLView
        partial      : 'My Account'
        cssClass     : 'HomeAppView--sectionHeader'
      username       :
        cssClass     : 'hidden'
        placeholder  : 'username'
        name         : 'username'
        label        : 'Username'
        attributes   :
          readonly   : "#{not /^guest-/.test @account.profile.nickname}"
        testPath     : 'account-username-input'
      firstName      :
        cssClass     : 'Formline--half'
        placeholder  : 'firstname'
        name         : 'firstName'
        label        : 'First Name'
      lastName       :
        cssClass     : 'Formline--half'
        placeholder  : 'lastname'
        name         : 'lastName'
        label        : 'Last Name'
      email          :
        cssClass     : 'Formline--half'
        placeholder  : 'you@yourdomain.com'
        name         : 'email'
        testPath     : 'account-email-input'
        label        : 'Email Address'


    @userProfileForm = new kd.FormViewWithFields
      cssClass   : 'HomeAppView--form'
      fields     : fields
      buttons    :
        Save     :
          title  : 'Save Changes'
          type   : 'submit'
          style  : 'solid green small'
          loader : yes
      callback   : @bound 'update'

    @once 'viewAppended', @bound 'init'


  init: ->

    { JPasswordRecovery, JUser } = remote.api
    { token } = kd.utils.parseQuery()
    if token
      JPasswordRecovery.validate token, (err, isValid) ->
        if err and err.short isnt 'redeemed_token'
          notify err.message
        else if isValid
          notify 'Thanks for confirming your email address'

    kd.singletons.mainController.ready =>
      whoami().fetchEmailAndStatus (err, userInfo) =>

        return kd.warn err  if err

        @userInfo = userInfo
        @putDefaults()


  uploadInputChange: ->

    @uploadAvatarBtn.showLoader()

    file = @uploadAvatarInput.getElement().files[0]

    return @uploadAvatarBtn.hideLoader()  unless file

    mimeType      = file.type
    reader        = new FileReader
    reader.onload = (event) =>
      dataURL     = event.target.result
      [_, base64] = dataURL.split ','

      @uploadAvatar
        mimeType : mimeType
        content  : file
      , =>
        @uploadAvatarBtn.hideLoader()

    reader.readAsDataURL file


  uploadAvatar: (avatar, callback) ->

    { mimeType, content } = avatar

    s3upload
      name    : "avatar-#{Date.now()}"
      content : content
      mimeType: mimeType
      timeout : 30000
    , (err, url) =>

      @uploadAvatarBtn.hideLoader()

      return showError err  if err

      @account.modify { 'profile.avatar': "#{url}" }


  update: (formData) ->

    { JUser } = remote.api
    { email, firstName, lastName } = formData
    queue = [
      (next) ->
        # update firstname and lastname
        me = whoami()

        me.modify {
          'profile.firstName': firstName,
          'profile.lastName' : lastName
          'shareLocation'    : formData.shareLocation
        }, (err) ->
          return next err.message  if err
          next()

      (next) =>
        return next() if email is @userInfo.email

        options = { email }
        @confirmCurrentPassword options, (err) =>
          return next err  if err

          JUser.changeEmail { email }, (err, result) =>
            return next err.message  if err

            modal = new VerifyPINModal 'Update E-Mail', (pin) =>
              remote.api.JUser.changeEmail { email, pin }, (err) =>
                return next err.message  if err
                @userInfo.email = email
                next()
            modal.once 'ModalCancelled', -> next 'cancelled'

      (next) ->
        notify 'Your account information is updated.'
        next()
    ]

    async.series queue, (err) =>
      notify err  if err and err isnt 'cancelled'
      @hideSaveButtonLoader()


  confirmCurrentPassword: (opts, callback) ->

    modal = new VerifyPasswordModal 'Confirm', (currentPassword) ->
      options = { password: currentPassword, email: opts.email }
      remote.api.JUser.verifyPassword options, (err, confirmed) ->

        return callback err.message  if err
        return callback 'Current password cannot be confirmed'  unless confirmed

        callback null

    @hideSaveButtonLoader()



  putDefaults: ->

    { email } = @userInfo
    { nickname, firstName, lastName } = @account.profile

    @userProfileForm.inputs.email.setDefaultValue Encoder.htmlDecode email
    @userProfileForm.inputs.username.setDefaultValue Encoder.htmlDecode nickname
    @userProfileForm.inputs.firstName.setDefaultValue Encoder.htmlDecode firstName
    @userProfileForm.inputs.lastName.setDefaultValue Encoder.htmlDecode lastName

    { focus } = kd.utils.parseQuery()
    @userProfileForm.inputs[focus]?.setFocus()  if focus

    notify = (message) ->
      new kd.NotificationView
        title    : message
        duration : 3500

    @userProfileForm.inputs.firstName.setFocus()


  getAvatarOptions: ->
    tagName       : 'figure'
    cssClass      : 'HomeAppView--account-avatar'
    size          :
      width       : 95
      height      : 95


  hideSaveButtonLoader: -> @userProfileForm.buttons.Save.hideLoader()


  pistachio: ->
    """
    <div class='HomeAppView--account-avatarArea clearfix'>
      {{> @avatar}}
      <div class="HomeAppView--account-avatarArea-buttons">
        {{> @uploadAvatarBtn}}
        {{> @uploadAvatarInput}}
        {{> @useGravatarBtn}}
      </div>
    </div>
    {{> @userProfileForm}}
    """
