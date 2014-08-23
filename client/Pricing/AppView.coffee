class PricingAppView extends KDView

  constructor:(options = {}, data) ->
    options.cssClass = KD.utils.curry "content-page pricing", options.cssClass
    super options, data

    # CtF I know this does not belongs here, but the problem was for the partial registration
    # there is an async situation of app storage operations caused by guest users/registered
    # members conversion
    @appStorage = KD.getSingleton('appStorageController').storage 'Login', '1.0'

    @productForm = new PricingProductForm name: "plan"
    @productForm.on "PlanSelected", (plan, options) =>
      @showBreadcrumb plan, options
      if "custom-plan" in plan.tags
        @addGroupForm()

  viewAppended: ->
    @addSubView @breadcrumb = new BreadcrumbView

    paymentController = KD.singleton "paymentController"
    @setWorkflow paymentController.createUpgradeWorkflow {@productForm}

  setWorkflow: (workflow) ->
    @workflow.destroy()  if @workflow
    @groupForm?.destroy()
    @thankYou?.destroy()
    @sorry?.destroy()

    workflow.on 'Finished', @bound "workflowFinished"
    workflow.on 'Cancel', @bound "cancel"
    workflow.on "SubscriptionTransitionCompleted", @bound "createGroup"
    workflow.off 'FormIsShown'

    workflow.on 'Failed', =>
      @hideWorkflow()
      @showGroupCreationFailed()

    workflow.on 'FormIsShown', (form) =>
      return  unless workflow.active
      @breadcrumb.selectItem workflow.active.getOption 'name'

    @addSubView @workflow = workflow

  showWorkflow: ->
    @workflow.show()

  hideWorkflow: ->
    @workflow.hide()

  workflowFinished: (@formData) ->
    @hideWorkflow()
    @showPaymentSucceded()  if "vm" in @formData.productData.plan.tags

  cancel: ->
    KD.singleton("router").handleRoute "/Activity"

  showBreadcrumb: (plan, options) ->
    @breadcrumb.show()
    @breadcrumb.showPlan plan, options  if plan and options

  hideBreadcrumb: ->
    @breadcrumb?.hide()
    document.body.classList.remove 'flow'

  showGroupForm: ->

    return  if @groupForm and not @groupForm.isDestroyed
    @hideWorkflow()
    @addSubView @groupForm = new PricingGroupForm

    @breadcrumb.selectItem 'details'

  showGroupCreationFailed: ->

    @addSubView @sorry = new KDView
      name     : "thanks"
      cssClass : "pricing-final payment-workflow"
      partial  :
        """
        <i class="error-icon"></i>
        <h3 class="pricing-title">Something went wrong!</h3>
        <h6 class="pricing-subtitle">We're sorry to tell that something unexpected has happened,<br/>please contact our support <a href='mailto:support@koding.com' target='_self'>support@koding.com</a>, we'll sort it out ASAP.</h6>
        """

    @sorry.addSubView new KDButtonView
      style    : "solid medium"
      title    : "Go back"
      callback : ->
        KD.singleton("router").handleRoute "/"

    @hideBreadcrumb()


  showPaymentSucceded: ->
    {createAccount, loggedIn} = @formData
    @breadcrumb.selectItem 'thanks'

    subtitle =
      if loggedIn then "Now it’s time, time to start Koding!"
      else "Go to your inbox to complete your registration"

    @addSubView @thankYou = new KDView
      cssClass : "pricing-final payment-workflow"
      partial  :
        """
        <i class="check-icon"></i>
        <h3 class="pricing-title">So much wow, so much horse-power!</h3>
        <h6 class="pricing-subtitle">#{subtitle}</h6>
        """

    if loggedIn
      @thankYou.addSubView new KDButtonView
        style    : "solid medium green"
        title    : "Go to your environment"
        callback : ->
          KD.singleton("router").handleRoute "/Environments"

  showGroupCreated: (group, subscription) ->
    {createAccount, loggedIn} = @formData
    @breadcrumb.selectItem 'thanks'

    planCodes = Object.keys subscription.quantities

    @addSubView @thankYou = new KDView
      cssClass : "pricing-final payment-workflow"
      partial  :
        """
        <i class="check-icon"></i>
        <h3 class="pricing-title"><strong>#{group.title}</strong> has been successfully created</h3>
        """

    KD.singleton("appManager").tell "Login", "setStorageData", "redirectTo", group.slug

    if loggedIn
      @thankYou.addSubView new KDButtonView
        style    : "solid medium green"
        title    : "Go to Group"
        callback : ->
          window.open "#{window.location.origin}/#{group.slug}", "_blank"
    else if createAccount
      @thankYou.addSubView new KDCustomHTMLView
        partial: "Go to your inbox to complete your registration"

  getCompleteYourRegistrationButton: ->
    return new KDButtonView
      style    : "solid green"
      title    : "Complete your registration"
      callback : =>
        log "Complete my registration"

  addGroupForm: ->
    @groupForm = new PricingGroupForm
    @groupForm.on "Submit", => @workflow.collectData "group": yes
    @workflow.requireData ["group"]
    @workflow.addForm "group", @groupForm, ["group"]
    @workflow.on "FormIsShown", (form) =>
      if form is @groupForm
        @breadcrumb.selectItem "details"

  createGroup: ->
    return  unless @groupForm
    groupName  = @groupForm.inputs.GroupName.getValue()
    visibility = @groupForm.inputs.Visibility.getValue()
    slug       = @groupForm.inputs.GroupSlug.getValue()

    options      =
      title      : groupName
      slug       : slug
      visibility : visibility

    {JGroup} = KD.remote.api
    JGroup.create options, (err, { group, subscription }) =>
      return KD.showError err  if err
      @showGroupCreated group, subscription
