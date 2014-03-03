class PricingAppView extends KDView

  constructor:(options = {}, data) ->
    super options, data
    # CtF I know this does not belongs here, but the problem was for the partial registration
    # there is an async situation of app storage operations caused by guest users/registered
    # members conversion
    @appStorage = KD.getSingleton('appStorageController').storage 'Login', '1.0'

  createBreadcrumb: ->
    @addSubView @breadcrumb = new BreadcrumbView


  setWorkflow: (workflow) ->
    @workflow.destroy()  if @workflow
    @groupForm?.destroy()
    @thankYou?.destroy()
    @sorry?.destroy()
    @hideBreadcrumb()

    @workflow = workflow
    @addSubView @workflow
    workflow.on 'Finished', @bound "workflowFinished"
    workflow.on 'Cancel', @bound "cancel"

    workflow.off 'FormIsShown'

    workflow.on 'GroupCreationFailed', =>
      @hideWorkflow()
      @showGroupCreationFailed()

    workflow.on 'FormIsShown', (form)=>
      return  unless workflow.active
      @breadcrumb.selectItem workflow.active.getOption 'name'

    workflow.once "PasswordRecoveryToken", (@recoveryToken) =>

  hideBreadcrumb:->
    @breadcrumb.hide()
    document.body.classList.remove 'flow'

  hideWorkflow: ->
    @workflow.hide()

  workflowFinished: (@formData) ->
    @hideWorkflow()
    @showPaymentSucceded()  if "vm" in @formData.productData.plan.tags

  cancel: ->
    KD.singleton("router").handleRoute "/Activity"

  showGroupForm: ->

    return  if @groupForm and not @groupForm.isDestroyed
    @hideWorkflow()
    @addSubView @groupForm = @createGroupForm()

    @breadcrumb.selectItem 'details'

  showGroupCreationFailed: ->

    @addSubView @sorry = new KDCustomHTMLView
      name     : "thanks"
      cssClass : "pricing-final"
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
      else ""

    @addSubView @thankYou = new KDCustomHTMLView
      cssClass : "pricing-final"
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
    else if createAccount
      @thankYou.addSubView @getCompleteYourRegistrationButton()

  showGroupCreated: (group, subscription) ->
    {createAccount, loggedIn} = @formData
    @breadcrumb.selectItem 'thanks'

    planCodes = Object.keys subscription.quantities

    @addSubView @thankYou = new KDCustomHTMLView
      cssClass : "pricing-final"
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
      @thankYou.addSubView @getCompleteYourRegistrationButton()

  getCompleteYourRegistrationButton: ->
    return new KDButtonView
      style    : "solid green"
      title    : "Complete your registration"
      callback : =>
        window.location.href = "/Register/#{encodeURIComponent @recoveryToken}"  if @recoveryToken

  addGroupForm: ->
    @groupForm = @createGroupForm()
    @groupForm.on "Submit", => @workflow.collectData "group": yes
    @workflow.requireData ["group"]
    @workflow.addForm "group", @groupForm, ["group"]

  createGroupForm: ->
    return groupForm = new KDFormViewWithFields
      title                 : "Enter new group name"
      cssClass              : "pricing-create-group"
      callback              : ->
        groupForm.buttons.Create.showLoader()
        @emit "Submit"
      buttons               :
        Create              :
          title             : "CREATE YOUR GROUP"
          type              : "submit"
          style             : "solid green medium"
          loader            : yes
          callback          : ->
      fields                :
        GroupName           :
          label             : "Group Name"
          name              : "groupName"
          placeholder       : "My Awesome Group"
          validate          :
            rules           :
              required      : yes
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
          validate          :
            rules           :
              minLength     : 3

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
