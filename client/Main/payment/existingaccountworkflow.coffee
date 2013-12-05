class ExistingAccountForm extends JView
  viewAppended: ->

    @exitingAccountButton = new KDButtonView
      title : "I have an account"
      callback: => @emit 'DataCollected', existingAccount: yes

    @createAccountButton = new KDButtonView
      title : "I'll create an account"
      callback: => @emit 'DataCollected', createAccount: yes

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

    @requireData any(
      
      all('createAccount', 'email')

      all('existingAccount', 'loggedIn')
    )

    existingAccountForm = new ExistingAccountForm
    existingAccountForm.on 'DataCollected', @bound 'collectData'

    @addForm 'existingAccount', existingAccountForm, [
      'createAccount'
      'existingAccount'
    ]

    loginForm = new LoginInlineForm
      cssClass : "login-form"
      testPath : "login-form"
      callback : (formData) => debugger

    @addForm 'login', loginForm, ['loggedIn']

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
      callback             : @bound 'collectData'

    @addForm 'email', emailCollectionForm, ['email']

    @enter()
