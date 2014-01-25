class PricingAppView extends KDView

  addWorkflow: (@workflow) ->
    @addSubView @workflow
    @workflow.on 'Finished', @bound "showThankYou"
    @workflow.on 'Cancel', @bound "showCancellation"

  hideWorkflow: ->
    @workflow.hide()

  showThankYou: (@workflowData, @subscription) ->
    @hideWorkflow()

    @thankYou = new KDCustomHTMLView
      partial:
        """
        <h1>Thank you!</h1>
        <p>
          Your order has been processed.
        </p>
        #{
          if @subscription.createAccount
          then "<p>Please check your email for your registration link.</p>"
          else "<p>We hope you enjoy your new subscription</p>"
        }
        """

    if "custom-plan" in @workflowData.productData.plan.tags
      @thankYou.addSubView @createGroupNameForm()

    @addSubView @thankYou

  createGroupNameForm: ->
    @groupForm              = new KDFormViewWithFields
      title                 : "Enter new group name"
      callback              : @bound "createGroup"
      buttons               :
        Create              :
          title             : "Create"
          type              : "submit"
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
          partial           : "#{location.protocol}//#{location.host}/"
        Privacy             :
          itemClass         : KDSelectBox
          label             : "Privacy"
          type              : "select"
          name              : "privacy"
          defaultValue      : "public"
          selectOptions     : [
            { title : "Public",    value : "public"  }
            { title : "Private",   value : "private" }
          ]
        Visibility          :
          itemClass         : KDSelectBox
          label             : "Visibility"
          type              : "select"
          name              : "visibility"
          defaultValue      : "hidden"
          selectOptions     : [
            { title : "Hidden",    value : "hidden"  }
            { title : "Visible",   value : "visible" }
          ]

  createGroup: ->
    groupName  = @groupForm.inputs.GroupName.getValue()
    privacy    = @groupForm.inputs.Privacy.getValue()
    visibility = @groupForm.inputs.Visibility.getValue()
    slug       = @groupForm.inputs.GroupUrl.getValue()

    options      =
      title      : groupName
      body       : groupName
      slug       : slug
      privacy    : privacy
      visibility : visibility

    KD.remote.api.JGroup.create options, (err, group)=>
      return KD.showError err if err
      @showSummaryModal group

  showSummaryModal: (group)->
    {planOptions: {userQuantity, resourceQuantity}} = @workflowData.productData

    modal              = new KDModalView
      title            : "Group successfully created"
      width            : 600
      overlay          : yes
      buttons          :
        "Go to Group"  :
          style        : "modal-clean-red"
          callback     : ->
            window.open "#{window.location.origin}/#{group.slug}", "_blank"
        Close          :
          style        : "modal-cancel"
          callback     : -> modal.destroy()
      content          :
        """
          <div>https://koding.com/#{group.slug}</div>
          <div>Users: #{userQuantity}</div>
          <div>Resource packs: #{resourceQuantity}</div>
        """

  checkSlug: ->
    slug      = @groupForm.inputs.GroupUrl
    slugView  = @groupForm.inputs.Slug
    tmpSlug   = slug.getValue()

    if tmpSlug.length > 2
      slugy = KD.utils.slugify tmpSlug
      KD.remote.api.JGroup.suggestUniqueSlug slugy, (err, newSlug)->
        slugView.updatePartial "#{location.origin}/#{newSlug}"
        slug.setValue newSlug

  showCancellation: ->
    @hideWorkflow()
    return  if @cancellation
    @cancellation = new KDView partial: "<h1>This order has been cancelled.</h1>"
    @addSubView @cancellation
