kd                   = require 'kd'
remote               = require('app/remote').getInstance()
JView                = require 'app/jview'
whoami               = require 'app/util/whoami'
VerifyPasswordModal  = require 'app/commonviews/verifypasswordmodal'
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

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    super options, data

    fields =
      password        :
        cssClass      : 'Formline--half'
        name          : 'password'
        type          : 'password'
        label         : 'Password'
      confirm         :
        cssClass      : 'Formline--half'
        name          : 'confirmPassword'
        type          : 'password'
        label         : 'Password (again)'
      currentPassword :
        cssClass      : 'Formline--half'
        name          : 'currentPassword'
        type          : 'password'
        label         : 'Current Password'

    @updatePasswordLink  = new CustomLinkView
      cssClass : 'HomeAppView--link blue'
      title    : 'UPDATE'
      click    : @bound 'update'

    @changePasswordForm = new kd.FormViewWithFields
      cssClass   : 'HomeAppView--form'
      fields     : fields

    @changePasswordForm.addSubView @updatePasswordLink


  update: (formData) ->

    { JUser } = remote.api
    { password, confirmPassword, currentPassword } = formData
    skipConfirmation = no

    notify_ = (msg) =>
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
    """
    {{> @changePasswordForm}}
    """
