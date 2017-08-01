kd                   = require 'kd'
remote               = require 'app/remote'

whoami               = require 'app/util/whoami'
CustomLinkView       = require 'app/customlinkview'

notify = (title, duration = 2000) -> new kd.NotificationView { title, duration }

WARNINGS =
  tooShort      : 'Passwords should be at least 8 characters!'
  noMatch       : 'Passwords did not match!'
  isOld         : 'You should enter a new password!'
  error         : 'An error occurred!'
  wrongPassword : 'Old password did not match our records!'
  success       : 'Password successfully changed!'

module.exports = class HomeAccountChangePassword extends kd.CustomHTMLView


  constructor: (options = {}, data) ->

    super options, data

    fields =
      password        :
        cssClass      : 'Formline--half'
        name          : 'password'
        type          : 'password'
        label         : 'New Password'
      confirm         :
        cssClass      : 'Formline--half'
        name          : 'confirmPassword'
        type          : 'password'
        label         : 'Repeat New Password'
      currentPassword :
        cssClass      : 'Formline--half'
        name          : 'currentPassword'
        type          : 'password'
        label         : 'Your Current Password'

    @updatePasswordLink  = new kd.ButtonView
      cssClass : 'GenericButton update-button'
      title    : 'UPDATE PASSWORD'
      callback : @bound 'update'

    @forgotPasswordLink = new CustomLinkView
      cssClass : 'HomeAppView--link'
      title : 'FORGOT PASSWORD'
      click : @bound 'forgotPassword'

    @changePasswordForm = new kd.FormViewWithFields
      cssClass   : 'HomeAppView--form'
      fields     : fields

    @buttonWrapper = new kd.CustomHTMLView
      cssClass : 'button-wrapper'

    @buttonWrapper.addSubView @forgotPasswordLink
    @buttonWrapper.addSubView @updatePasswordLink


  forgotPassword: (event) ->

    account = whoami()
    account.fetchEmail (err, email) =>
      return @showError err  if err
      @doRecover email

  doRecover: (email) ->
    $.ajax
      url         : '/Recover'
      data        : { email, _csrf : Cookies.get '_csrf' }
      type        : 'POST'
      error       : (xhr) ->
        { responseText } = xhr
        new kd.NotificationView { title : responseText }
      success     : ->
        new kd.NotificationView
          title     : 'Check your email'
          content   : "We've sent you a password recovery code."
          duration  : 4500



  update: (event) ->

    { JUser } = remote.api
    { password, confirmPassword, currentPassword } = @changePasswordForm.getData()
    skipConfirmation = no

    notify_ = (msg) ->
      notify msg

    return notify_ WARNINGS.noMatch   if password isnt confirmPassword
    return notify_ WARNINGS.tooShort  if password.length < 8
    return notify_ WARNINGS.isOld     if password is currentPassword

    JUser.fetchUser (err, user) =>
      return notify_ WARNINGS.error  if err

      skipConfirmation = yes  if user.passwordStatus isnt 'valid'
      @confirmCurrentPassword { skipConfirmation, currentPassword }, (err) =>
        return notify_ err  if err
        JUser.changePassword password, (err) =>
          return notify_ err.message  if err
          notify_ WARNINGS.success
          @clearForm()


  confirmCurrentPassword: (opts, callback) ->

    { skipConfirmation, email, currentPassword } = opts

    return callback null  if skipConfirmation

    options = { password: currentPassword, email }
    remote.api.JUser.verifyPassword options, (err, confirmed) ->

      return callback err.message             if err
      return callback WARNINGS.wrongPassword  unless confirmed

      callback null


  clearForm: ->

    @changePasswordForm.inputs.password.setValue ''
    @changePasswordForm.inputs.confirm.setValue ''
    @changePasswordForm.inputs.currentPassword.setValue ''


  pistachio: ->
    '''
    {{> @changePasswordForm}}
    {{> @buttonWrapper}}
    '''
