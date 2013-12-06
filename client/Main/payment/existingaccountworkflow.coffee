class ExistingAccountForm extends JView
  viewAppended: ->

    @exitingAccountButton = new KDButtonView
      title : "I have an account"
      callback: => @emit 'DataCollected',
        createAccount : no
        email         : no

    @createAccountButton = new KDButtonView
      title : "I'll create an account"
      callback: => @emit 'DataCollected',
        createAccount : yes
        account       : yes

    super()

  pistachio: ->
    """
    Are you an existing user?
    {{> @exitingAccountButton}}
    {{> @createAccountButton}}
    """

class ExistingAccountWorkflow extends FormWorkflow

  prepareWorkflow: ->
    { all, any } = Junction

    @requireData all(
      'createAccount'
      'email'
      'loggedIn'
    )

    existingAccountForm = new ExistingAccountForm
    existingAccountForm.on 'DataCollected', (data) =>
      @collectData data

    @addForm 'existingAccount', existingAccountForm, [
      'createAccount'
    ]

    emailCollectionForm = new KDFormViewWithFields
      fields:
        email:
          cssClass         : "thin"
          placeholder      : "you@yourdomain.com"
          name             : "email"
          testPath         : "account-email-input"
      buttons              :
        Save               :
          type             : 'submit'
          style            : 'solid green fr'
      callback             : ({ email }) =>
        { JUser } = KD.remote.api

        JUser.changeEmail { email }, (err) =>
          return  if KD.showError err

          @collectData { email, loggedIn: no }

    emailCollectionForm.activate = -> @inputs.email.setFocus()

    @addForm 'email', emailCollectionForm, ['email']

    loginForm = new LoginInlineForm
      cssClass : "login-form"
      testPath : "login-form"
      callback : (credentials) =>
        KD.getSingleton('mainController').handleLogin credentials, (err) =>
          @collectData loggedIn: yes

    @addForm 'login', loginForm, ['loggedIn']

    @enter()
