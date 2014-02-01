class PricingAppView extends KDView

  addWorkflow: (@workflow) ->
    @addSubView @workflow
    @workflow.on 'Finished', @bound "workflowFinished"
    @workflow.on 'Cancel', @bound "showCancellation"

  hideWorkflow: ->
    @workflow.hide()

  workflowFinished: (@formData, @subscription, @nonce) ->
    @hideWorkflow()

    {productData: {plan: {tags}}} = @formData
    if "vm" in tags
    then @showPaymentSucceded()
    else if "custom-plan" in tags
    then @showGroupForm()

  showCancellation: ->
    return  if @cancellation
    @hideWorkflow()
    @cancellation = new KDView partial: "<h1>This order has been cancelled.</h1>"
    @addSubView @cancellation

  showGroupForm: ->
    return  if @groupForm and not @groupForm.isDestroyed
    @hideWorkflow()
    @addSubView @groupForm = @createGroupForm()

  showPaymentSucceded: ->
    subtitle =
      if @formData.createAccount
      then "Please check your email to complete your registration."
      else "Now it’s time, time to start Koding!"

    @addSubView thankYou = new KDCustomHTMLView
      cssClass : "pricing-thank-you"
      partial  :
        """
        <i class="check-icon"></i>
        <h3 class="pricing-title">So much wow, so much horse-power!</h3>
        <h6 class="pricing-subtitle">#{subtitle}</h6>
        """

    if @formData.loggedIn
      thankYou.addSubView new KDButtonView
        style    : "solid green"
        title    : "Go to your environment"
        callback : ->
          KD.singleton("router").handleRoute "/Environments"

  showGroupCreated: (group, subscription) ->
    planCodes = Object.keys subscription.quantities
    KD.remote.api.JPaymentProduct.some {planCode: $in: planCodes}, limit: 30, (err, products) =>
      return  if KD.showError err

      subtitle =
        if @formData.createAccount
        then "Please check your email to complete your registration."
        else ""

      @addSubView thankYou = new KDCustomHTMLView
        cssClass : "pricing-thank-you"
        partial  :
          """
          <i class="check-icon"></i>
          <h3 class="pricing-title"><strong>#{group.title}</strong> has been successfully created</h3>
          <h6 class="pricing-subtitle">#{subtitle}</h6>
          """

      productList = products.map (product) ->
        "<div>#{subscription.quantities[product.planCode]}x #{product.title}</div>"

      thankYou.addSubView new KDCustomHTMLView
        cssClass : "product-list"
        partial  : productList.join ""

      if @formData.loggedIn
        thankYou.addSubView new KDButtonView
          title    : "Go to Group"
          callback : ->
            window.open "#{window.location.origin}/#{group.slug}", "_blank"

  createGroupForm: ->
    return new KDFormViewWithFields
      title                 : "Enter new group name"
      cssClass              : "pricing-create-group"
      callback              : @bound "createGroup"
      buttons               :
        Create              :
          title             : "Create"
          type              : "submit"
          style             : "solid green"
      fields                :
        GroupName           :
          label             : "Group Name"
          type              : "text"
          name              : "groupName"
          placeholder       : "enter group name..."
          validate          :
            rules           :
              required      : yes
            messages        :
              required      : "Group name required"
        GroupUrl            :
          label             : "Group URL"
          type              : "text"
          name              : "groupURL"
          placeholder       : "enter group url..."
          keyup             : KD.utils.defer.bind this, @bound "checkSlug"
          validate          :
            rules           :
              required      : yes
            messages        :
              required      : "Group name required"
        Slug                :
          label             : "Address"
          itemClass         : KDCustomHTMLView
          partial           : "#{window.location.origin}"
        Visibility          :
          itemClass         : KDSelectBox
          label             : "Visibility"
          type              : "select"
          name              : "visibility"
          defaultValue      : "hidden"
          selectOptions     : [
            title : "Hidden" ,   value : "hidden"
            title : "Visible",   value : "visible"
          ]

  createGroup: ->
    groupName  = @groupForm.inputs.GroupName.getValue()
    visibility = @groupForm.inputs.Visibility.getValue()
    slug       = @groupForm.inputs.GroupUrl.getValue()

    options      =
      title      : groupName
      body       : groupName
      slug       : slug
      visibility : visibility
      nonce      : @nonce

    {JGroup} = KD.remote.api
    JGroup.create options, (err, group, subscription) =>
      return KD.showError err  if err

      @groupForm.destroy()
      @showGroupCreated group, subscription

      # enter first post of group.
      JGroup.createGroupBotAndPostMessage
        title   : "Welcome"
        body    : "Welcome to your group."
        botname : "groupbot"
      , (err) ->
        KD.showError err

  checkSlug: ->
    slug      = @groupForm.inputs.GroupUrl
    slugView  = @groupForm.inputs.Slug
    tmpSlug   = slug.getValue()

    if tmpSlug.length > 2
      slugy = KD.utils.slugify tmpSlug
      KD.remote.api.JGroup.suggestUniqueSlug slugy, (err, newSlug)->
        slugView.updatePartial "#{location.origin}/#{newSlug}"
        slug.setValue newSlug
