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
    @existingAccountForm = new ExistingAccountForm
    @existingAccountForm.on 'DataCollected', @bound "collectData"
    @addForm 'existingAccount', @existingAccountForm, ['createAccount', 'loggedIn']
    @enter()

  createProductView: (plan)->
    productList = new PlanProductListView {plan}
    @existingAccountForm.addSubView productList


class PlanProductListView extends KDView
  constructor: (options = {}, data) ->
    super options, data

    {@plan} = @getOptions()

    @quantititesList = new KDListViewController
      startWithLazyLoader    : no
      view                   : new KDListView
        type                 : "products"
        cssClass             : "product-item-list"
        itemClass            : PlanProductListItemView

    @plan.fetchProducts (err,products)=>
      return new KDNotificationView title : err if err
      for product in products
        quantity = @plan.quantities[product.planCode]
        @quantititesList.addItem {product,quantity}

    @listView = @quantititesList.getView()


  viewAppended:JView::viewAppended

  pistachio:->
    total = KD.utils.formatMoney @plan.feeAmount / 100
    """
      #{@plan.title}
      {{> @listView}}
      Total Amount : #{total}
    """


class PlanProductListItemView extends KDListItemView
  constructor:(options = {}, data)->
    options.tagName    = 'span'
    super options, data

    {@title} = @getData().product
    {@quantity} = @getData()

  viewAppended:JView::viewAppended

  pistachio:->
    """
    #{@title} - #{@quantity}
    """
