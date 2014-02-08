class ExistingAccountForm extends JView
  viewAppended: ->

    KD.singletons.dock.getView().hide()

    @loginForm = new LoginInlineForm
      cssClass : "login-form clearfix"
      testPath : "login-form"
      callback : (credentials) =>
        KD.getSingleton('mainController').handleLogin credentials, (err) =>
          @loginForm.button.hideLoader()
          if (KD.showError err)
            if err?.field of @loginForm
              @loginForm[err.field].decorateValidation err
          else
            localStorage?.setItem "routeToBeContinued", KD.singleton("router").currentPath
            @emit "DataCollected", loggedIn: yes

    @emailCollectionForm = new KDFormViewWithFields
      fields:
        email:
          cssClass         : "thin"
          placeholder      : "you@yourdomain.com"
          name             : "email"
          testPath         : "account-email-input"
      buttons              :
        'SIGN UP'          :
          type             : 'submit'
          style            : 'solid green fr'
      callback             : ({ email }) =>
        KD.remote.api.JUser.changeEmail { email }, (err) =>
          return  if KD.showError err
          @emit 'DataCollected', createAccount: yes, email: email

    super

  pistachio: ->
    """
    <section class="pricing-sign-in clearfix">
      <h4 class="pricing-title"><span class="current">sign in</span> - payment info - place order</h4>
      <h3 class="pricing-title">Sign in or create an account to proceed with your checkout</h3>
      {{> @loginForm}}
      <span class="divider">or</span>
      {{> @emailCollectionForm}}
    </section>
    """

class ExistingAccountWorkflow extends FormWorkflow
  prepareWorkflow: ->
    @requireData Junction.any 'createAccount', 'loggedIn'
    existingAccountForm = new ExistingAccountForm
    existingAccountForm.on 'DataCollected', @bound "collectData"
    @addForm 'existingAccount', existingAccountForm, ['createAccount', 'loggedIn']
    @enter()
