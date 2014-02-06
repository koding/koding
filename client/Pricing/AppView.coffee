class PricingAppView extends KDView

  setWorkflow: (workflow) ->
    @workflow.destroy()  if @workflow
    @groupForm?.destroy()
    @thankYou?.destroy()

    @workflow = workflow
    @addSubView @workflow
    workflow.on 'Finished', @bound "workflowFinished"
    workflow.on 'Cancel', @bound "cancel"

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
          title             : "CREATE"
          type              : "submit"
          style             : "solid green"
      fields                :
        GroupName           :
          label             : "Group Name"
          type              : "text"
          name              : "groupName"
          validate          :
            rules           :
              required      : yes
            messages        :
              required      : "Group name required"
        GroupUrl            :
          label             : "Group URL"
          type              : "text"
          name              : "groupURL"
          placeholder       : "#{window.location.origin}"
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
            { title : "Hidden" ,   value : "hidden"  }
            { title : "Visible",   value : "visible" }
          ]

  createGroup: ->
    return  unless @groupForm
    groupName  = @groupForm.inputs.GroupName.getValue()
    visibility = @groupForm.inputs.Visibility.getValue()
    slug       = @groupForm.inputs.GroupUrl.getValue()

    options      =
      title      : groupName
      body       : groupName
      slug       : slug
      visibility : visibility

    {JGroup} = KD.remote.api
    JGroup.create options, (err, group, subscription) =>
      return KD.showError err  if err
      @showGroupCreated group, subscription

  checkSlug: ->
    slug      = @groupForm.inputs.GroupUrl
    slugView  = @groupForm.inputs.Slug
    tmpSlug   = slug.getValue()

    if tmpSlug.length > 2
      slugy = KD.utils.slugify tmpSlug
      KD.remote.api.JGroup.suggestUniqueSlug slugy, (err, newSlug)->
        slugView.updatePartial "#{location.origin}/#{newSlug}"
        slug.setValue newSlug
