class ExistingAccountForm extends JView
  viewAppended: ->

    log 'KD.singletons.dock.getView().hide()'

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

    # @emailCollectionForm = new KDFormViewWithFields
    #   buttons              :
    #     'Register'         :
    #       type             : 'submit'
    #       style            : 'solid green fr'
    #   callback             : -> KD.singletons.router.handleRoute '/Register'

    @registerButton = new KDButtonView
      title    : 'Register'
      cssClass : 'solid green fr'
      callback : -> KD.singletons.router.handleRoute '/Register'

    super

  pistachio: ->
    """
    <section class="pricing-sign-in clearfix">
      <h3 class="pricing-title">Sign in or create an account to proceed with your checkout</h3>
      <div class="form-wrapper">
        {{> @loginForm}}
        <span class="divider">or</span>
        {{> @registerButton }}
      </div>
    </section>
    """

class ExistingAccountWorkflow extends FormWorkflow
  prepareWorkflow: ->
    @requireData Junction.any 'createAccount', 'loggedIn'
    @existingAccountForm = new ExistingAccountForm name : 'login'
    @existingAccountForm.on 'DataCollected', @bound "collectData"
    @addForm 'existingAccount', @existingAccountForm, ['createAccount', 'loggedIn']
    @enter()
