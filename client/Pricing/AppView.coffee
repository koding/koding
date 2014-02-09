class BreadcrumbView extends JView


  constructor : (options = {}, data) ->

    options.cssClass  = KD.utils.curry "pricing-breadcrumb hidden", options.cssClass

    super options, data

    @checkOutButton = new KDButtonView
      title     : "CHECK OUT"
      cssClass  : "checkout-button"
      style     : "small solid yellow"

    @planName       = new KDCustomHTMLView
      tagName   : "span"

    @planProducts   = new KDCustomHTMLView
      tagName   : "span"
      cssClass  : "products"

    @planPrice      = new KDCustomHTMLView
      tagName   : "span"
      cssClass  : "price"


  selectItem : (name) ->

    return  unless name

    @$('li').removeClass "active"
    @$("li.#{name}").addClass "active"


  showPlan : (plan) ->

    {title, feeAmount, feeUnit} = plan

    feeAmount = feeAmount/100

    @show()
    document.body.classList.add 'flow'
    @planName.updatePartial title
    @planPrice.updatePartial "#{feeAmount}$/#{feeUnit}"

    if 'custom-plan' in plan.tags
    then @setClass 'team'
    else @unsetClass 'team'

    plan.fetchProducts (err, products) =>

      partial = ""

      for product in products

        {title, planCode} = product
        quantity          = plan.quantities[planCode]
        partial          += "#{quantity} #{title} - "

      partial = partial.substring(0, partial.length - 2)

      @planProducts.updatePartial partial


  pistachio : ->
    """
      <ul class='clearfix logged-#{if KD.isLoggedIn() then 'in' else 'out'}'>
        <li class='login active'>Login/Register</li>
        <li class='method'>Payment method</li>
        <li class='overview'>Overview</li>
        <li class='details hidden'>Group details</li>
        <li class='thanks'>Thank you</li>
      </ul>
      <section>
        <h4>Your plan</h4>
        {{> @planName }}
        {{> @planProducts }}
        {{> @planPrice }}
      </section>
    """

class PricingAppView extends KDView

  createBreadcrumb: ->
    @addSubView @breadcrumb = new BreadcrumbView


  setWorkflow: (workflow) ->
    @workflow.destroy()  if @workflow
    @groupForm?.destroy()
    @thankYou?.destroy()

    @breadcrumb.hide()
    document.body.classList.remove 'flow'

    @workflow = workflow
    @addSubView @workflow
    workflow.on 'Finished', @bound "workflowFinished"
    workflow.on 'Cancel', @bound "cancel"

    workflow.off 'FormIsShown'

    workflow.on 'FormIsShown', (form)=>
      return  unless workflow.active
      @breadcrumb.selectItem workflow.active.getOption 'name'



  hideWorkflow: ->
    @workflow.hide()

  workflowFinished: (@formData) ->
    @hideWorkflow()
    @showPaymentSucceded()  if "vm" in @formData.productData.plan.tags

  cancel: ->
    KD.singleton("router").handleRoute "/Pricing/Developer"

  showGroupForm: ->

    return  if @groupForm and not @groupForm.isDestroyed
    @hideWorkflow()
    @addSubView @groupForm = @createGroupForm()

  showPaymentSucceded: ->
    {createAccount, loggedIn} = @formData

    @breadcrumb.selectItem 'thanks'

    subtitle =
      if createAccount
      then "Please check your email to complete your registration."
      else "Now it’s time, time to start Koding!"

    @addSubView @thankYou = new KDCustomHTMLView
      cssClass : "pricing-thank-you"
      partial  :
        """
        <i class="check-icon"></i>
        <h3 class="pricing-title">So much wow, so much horse-power!</h3>
        <h6 class="pricing-subtitle">#{subtitle}</h6>
        """

    if loggedIn
      @thankYou.addSubView new KDButtonView
        style    : "solid green"
        title    : "Go to your environment"
        callback : ->
          KD.singleton("router").handleRoute "/Environments"

  showGroupCreated: (group, subscription) ->

    @breadcrumb.selectItem 'thanks'

    planCodes = Object.keys subscription.quantities
    subtitle =
      if @formData.createAccount
      then "Please check your email to complete your registration."
      else ""

    @addSubView @thankYou = new KDCustomHTMLView
      cssClass : "pricing-thank-you"
      partial  :
        """
        <i class="check-icon"></i>
        <h3 class="pricing-title"><strong>#{group.title}</strong> has been successfully created</h3>
        <h6 class="pricing-subtitle">#{subtitle}</h6>
        """

    if @formData.loggedIn
      @thankYou.addSubView new KDButtonView
        style    : "solid green"
        title    : "Go to Group"
        callback : ->
          window.open "#{window.location.origin}/#{group.slug}", "_blank"

  addGroupForm: ->
    @groupForm = @createGroupForm()
    @groupForm.on "Submit", => @workflow.collectData "group": yes
    @workflow.requireData ["group"]
    @workflow.addForm "group", @groupForm, ["group"]

  createGroupForm: ->
    return new KDFormViewWithFields
      title                 : "Enter new group name"
      cssClass              : "pricing-create-group"
      callback              : -> @emit "Submit"
      buttons               :
        Create              :
          title             : "CREATE YOUR GROUP"
          type              : "submit"
          style             : "solid green"
      fields                :
        GroupName           :
          label             : "Group Name"
          name              : "groupName"
          placeholder       : "My Awesome Group"
          keyup             : =>
            @checkSlug @groupForm.inputs.GroupName.getValue()
          validate          :
            rules           :
              required      : yes
            messages        :
              required      : "Group name required"
        GroupURL            :
          label             : "Group address"
          defaultValue      : "#{window.location.origin}/"
          # disabled          : yes
          keyup             : =>
            splittedUrl = @groupForm.inputs.GroupURL.getValue().split "/"
            @checkSlug splittedUrl.last

          # don't push it in if you can't do it right! - SY

          # nextElement       :
          #   changeURL       :
          #     itemClass     : KDCustomHTMLView
          #     tagName       : "a"
          #     partial       : 'change'
          #     click         : =>
          #       @groupForm.inputs.GroupURL.makeEnabled()
          #       @groupForm.inputs.GroupURL.focus()
        GroupSlug           :
          type              : "hidden"
          name              : "groupSlug"

        Visibility          :
          itemClass         : KDSelectBox
          label             : "Visibility"
          type              : "select"
          name              : "visibility"
          defaultValue      : "hidden"
          selectOptions     : [
            { title : "Hidden" ,   value : "hidden"  }
            { title : "Visible",   value : "visible" }
          ]

  createGroup: ->
    return  unless @groupForm
    groupName  = @groupForm.inputs.GroupName.getValue()
    visibility = @groupForm.inputs.Visibility.getValue()
    slug       = @groupForm.inputs.GroupSlug.getValue()

    options      =
      title      : groupName
      body       : groupName
      slug       : slug
      visibility : visibility

    {JGroup} = KD.remote.api
    JGroup.create options, (err, group, subscription) =>
      return KD.showError err  if err
      @showGroupCreated group, subscription

  checkSlug: (testSlug)->
    {GroupURL, GroupSlug} = @groupForm.inputs

    if testSlug.length > 2
      slugy = KD.utils.slugify testSlug
      KD.remote.api.JGroup.suggestUniqueSlug slugy, (err, newSlug)->
        GroupURL.setValue "#{location.origin}/#{newSlug}"
        GroupSlug.setValue newSlug

