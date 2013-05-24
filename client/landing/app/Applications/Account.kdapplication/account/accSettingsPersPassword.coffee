

class AccountEditSecurity extends KDView
  viewAppended:->
    # =================
    # ADDING PASSWORD FORM
    # =================
    @addSubView @passwordForm = passwordForm = new KDFormView
      callback     : @saveNewPassword.bind @

    passwordForm.addSubView passwordLabel = new KDLabelView
      title        : "Your password"
      cssClass     : "main-label"

    passwordInputs = new KDView cssClass : "hiddenval clearfix passwords"
    passwordInputs.addSubView passwordInput = new KDInputView
      label         : passwordLabel
      type          : "password"
      placeholder   : "type new password"
      name          : "password"
      validate      :
        rules       :
          required  : yes
        messages    :
          required  : "Password can't be empty..."


    passwordInputs.addSubView passwordConfirm = new KDInputView
      type          : "password"
      placeholder   : "re-type new password"
      name          : "passwordConfirm"
      validate      :
        rules       :
          match     : passwordInput
        messages    :
          match     : "Passwords do not match."

    passwordInputs.addSubView inputActions = new KDView cssClass : "actions-wrapper"
    inputActions.addSubView passwordSave = new KDButtonView
      title         : "Save"
      type          : 'submit'


    inputActions.addSubView passwordCancel = new KDCustomHTMLView
      tagName      : "a"
      partial      : "cancel"
      cssClass     : "cancel-link"
      click        : => @passwordSwappable.swapViews()

    # password STATIC PART
    nonPasswordInputs = new KDView cssClass : "initialval clearfix"
    nonPasswordInputs.addSubView passwordSpan = new KDCustomHTMLView
      tagName      : "span"
      partial      : "<i>your super secret password</i>"
      cssClass     : "static-text"
    nonPasswordInputs.addSubView passwordEdit = new KDCustomHTMLView
      tagName      : "a"
      partial      : "Edit"
      cssClass     : "action-link"
      click        : => @passwordSwappable.swapViews()

    passwordForm.addSubView @passwordSwappable = new AccountsSwappable
      views    : [passwordInputs, nonPasswordInputs]
      cssClass : "clearfix"

  passwordDidUpdate:->
    @passwordSwappable.swapViews()
    new KDNotificationView
      type : "growl"
      title : "Password Updated!"
      duration : 1000

  saveNewPassword:(formData)->
    KD.remote.api.JUser.changePassword formData.password,(err,docs)=>
      unless err then do @passwordDidUpdate
