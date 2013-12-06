class ExistingAccountForm extends JView
  viewAppended: ->

    @exitingAccountButton = new KDButtonView
      title : "I have an account"
      callback: => @emit 'DataCollected',
        account : yes
        email   : no

    @createAccountButton = new KDButtonView
      title : "I'll create an account"
      callback: => @emit 'DataCollected',
        account   : yes

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
      'account'
      'email'
      'loggedIn'
    )

    existingAccountForm = new ExistingAccountForm
    existingAccountForm.on 'DataCollected', (data) =>
      # @clearData 'createAccount'  if 'existingAccount' of data
      @collectData data

    @addForm 'existingAccount', existingAccountForm, [
      'account'
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
          title            : 'SAVE CHANGES'
          type             : 'submit'
          style            : 'solid green fr'
      callback             : ({ email }) =>
        @collectData { email, loggedIn: no }

    @addForm 'email', emailCollectionForm, ['email']

    loginForm = new LoginInlineForm
      cssClass : "login-form"
      testPath : "login-form"
      callback : (credentials) =>
        KD.getSingleton('mainController').handleLogin credentials, (err) =>
          @collectData loggedIn: yes

    @addForm 'login', loginForm, ['loggedIn']

    @enter()
