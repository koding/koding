kd                   = require 'kd'
KDCustomHTMLView     = kd.CustomHTMLView
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
CustomLinkView       = require 'app/customlinkview'

notify = (title, duration = 2000) -> new kd.NotificationView { title, duration }


module.exports = class HomeAccountEditProfile extends KDCustomHTMLView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    super options, data

    @account = whoami()

    @avatar = new AvatarStaticView @getAvatarOptions(), @account

    @changeAvatarLink  = new CustomLinkView
      cssClass : 'HomeAppView--link primary'
      title    : 'CHANGE AVATAR'

    @uploadAvatarInput = new kd.InputView
      type       : 'file'
      cssClass   : 'HomeAppView--account-avatarArea-links-upload'
      change     : @bound 'uploadInputChange'
      attributes :
        accept   : 'image/*'

    @useGravatarLink  = new CustomLinkView
      cssClass : 'HomeAppView--link'
      title    : 'USE GRAVATAR'
      click    : =>
        @account.modify { 'profile.avatar' : '' }, (err) =>
          console.warn err  if err

    @avatarButtons = new KDCustomHTMLView
      cssClass : 'HomeAppView--account-avatarArea-links'

    @avatarButtons.addSubView @useGravatarLink
    @avatarButtons.addSubView @changeAvatarLink
    @avatarButtons.addSubView @uploadAvatarInput


    fields =
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

    @submitButton = new kd.ButtonView
      type     : 'submit'
      loader   : yes
      style    : 'solid green small'
      title    : 'Save Changes'
      callback : @bound 'update'

    @userProfileForm = new kd.FormViewWithFields
      cssClass   : 'HomeAppView--form'
      fields     : fields

    @userProfileForm.addSubView @avatar
    @userProfileForm.addSubView @avatarButtons
    @userProfileForm.addSubView @submitButton

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

    file = @uploadAvatarInput.getElement().files[0]

    return unless file

    mimeType      = file.type
    reader        = new FileReader
    reader.onload = (event) =>
      dataURL     = event.target.result
      [_, base64] = dataURL.split ','

      @uploadAvatar
        mimeType : mimeType
        content  : file

    reader.readAsDataURL file


  uploadAvatar: (avatar, callback) ->

    { mimeType, content } = avatar

    s3upload
      name    : "avatar-#{Date.now()}"
      content : content
      mimeType: mimeType
      timeout : 30000
    , (err, url) =>

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
      width       : 132
      height      : 132


  hideSaveButtonLoader: -> @userProfileForm.buttons.Save.hideLoader()


  pistachio: ->
    """
    {{> @userProfileForm}}
    """
