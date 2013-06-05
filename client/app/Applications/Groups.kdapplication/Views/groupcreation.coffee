class GroupCreationModal extends KDModalView

  GROUP_TYPES = [
    { title : "University/School", value : "educational" }
    { title : "Company",           value : "company" }
    { title : "Project",           value : "project" }
    { title : "Other",             value : "custom" }
  ]

  constructor:(options = {}, data)->

    options.title    or= 'Create a new group'
    options.height   or= 'auto'
    options.cssClass or= "group-creation-modal"
    options.width     ?= 684
    options.overlay   ?= yes
    options.buttons    =
      submit           :
        title          : "Create"
        style          : "modal-clean-gray hidden"
        type           : "button"
        callback       : @bound "createGroup"
      next             :
        title          : "Next"
        style          : "modal-clean-gray hidden"
        type           : "button"
        callback       : @bound "next"
      back             :
        title          : "back"
        style          : "modal-cancel hidden"
        type           : "button"
        callback       : @bound "back"

    super options, data

    @plans = []

  fetchRecurlyPlans:(callback)-> KD.remote.api.JRecurlyPlan.getPlans "group", "vm", callback

  charge:(plan, callback)-> plan.subscribe { pin: '0000' }, callback

  setPositions:->
    super
    $scroller = @$('.kdmodal-content').eq(0)
    $scroller?.scrollTop $scroller[0].scrollHeight

  viewAppended:->

    @addSubView @typeSelector = new KDFormViewWithFields
      cssClass      : "type-selector"
      fields        :
        label       :
          itemClass : KDCustomHTMLView
          tagName   : 'h2'
          cssClass  : 'heading'
          partial   : "<span>1</span> What will be this group for?"
        selector    :
          name      : "type"
          itemClass : GroupCreationSelector
          cssClass  : "group-type"
          radios    : GROUP_TYPES
          change    : =>
            @ready =>
              typeSelector = @typeSelector.inputs.selector
              hostSelector = @hostSelector.inputs.selector

              @hostSelector?.show()

              hostSelector.setValue switch typeSelector.getValue()
                when "educational" then "4"
                when "company"     then "2"
                when "project"     then "1"
                when "custom"      then "0"

              @setPositions()

    @addSubView @mainSettings = new KDFormViewWithFields
      cssClass                 : "general-settings hidden"
      fields                   :
        "Title"                :
          label                : "Title"
          name                 : "title"
          validate             :
            event              : "blur"
            rules              :
              required         : yes
              minLength        : 4
          keyup                : KD.utils.defer.bind this, @bound "makeSlug"
          placeholder          : 'Please enter your group title...'
        "HiddenSlug"           : { name : "slug", type : "hidden", cssClass : "hidden" }
        "Slug"                 :
          label                : "Address"
          partial              : "#{location.protocol}//#{location.host}/"
          itemClass            : KDCustomHTMLView
        "Description"          :
          label                : "Description"
          type                 : "textarea"
          name                 : "body"
          placeholder          : "Please enter a description for your group here..."
        "Privacy"              :
          label                : "Privacy/Visibility"
          itemClass            : KDSelectBox
          type                 : "select"
          name                 : "privacy"
          defaultValue         : "public"
          selectOptions        :
            Public             : [ { title : "Anyone can join",    value : "public" } ]
            Private            : [
              { title : "By invitation",       value : "by-invite" }
              { title : "By access request",   value : "by-request" }
              { title : "In same domain",      value : "same-domain" }
            ]
          nextElement          :
            "Visibility"       :
              itemClass        : KDSelectBox
              type             : "select"
              name             : "visibility"
              defaultValue     : "visible"
              cssClass         : "visibility"
              selectOptions    : [
                { title : "Visible in group listings", value : "visible" }
                { title : "Hidden in group listings",  value : "hidden" }
              ]

    @fetchRecurlyPlans (err, plans)=>
      if plans
        plans.sort (a, b)-> a.feeMonthly - b.feeMonthly
        @plans = plans

      # fix this one on radios value cannot have some chars and that's why i keep index as the value
      descriptions = []
      hostTypes    = plans.map (plan, i)->
        descriptions.push item = try
          JSON.parse plan.desc.replace /&quot;/g, '"'
        catch e
          title       : ""
          description : plan.desc
          meta        : goodFor : 0
        plans[i].item = item
        feeMonthly = (plan.feeMonthly/100).toFixed 0
        { title : item.title, value : i, feeMonthly }

      descPartial = ""
      for d in descriptions
        descPartial += """
          <section>
            <p>
              <i>Good for:</i>
              <span>#{d.meta.goodFor}</span>
              <cite>users</cite>
            </p>
            #{d.description}
          </section>"""

      @addSubView @hostSelector = new KDFormViewWithFields
        cssClass      : "hidden host-selector"
        fields        :
          label       :
            itemClass : KDCustomHTMLView
            tagName   : 'h2'
            cssClass  : 'heading'
            partial   : "<span>2</span> How big should the host server be?"
          selector    :
            name      : "host"
            itemClass : HostCreationSelector
            cssClass  : "host-type"
            radios    : hostTypes
            change    : @bound "hostChanged"
          desc        :
            itemClass : KDCustomHTMLView
            cssClass  : "description-field hidden"
            partial   : descPartial

      @emit 'ready'

  hostChanged:->
    {next}           = @buttons
    {desc, selector} = @hostSelector.inputs
    descField        = @hostSelector.fields.desc

    descField.show()
    desc.show()

    index      = parseInt selector.getValue(), 10
    monthlyFee = (@plans[index].feeMonthly/100).toFixed(2)

    next.show()
    desc.$('section').addClass 'hidden'
    desc.$('section').eq(index).removeClass 'hidden'

    @setPositions()

  back:->

    {back, next, submit} = @buttons
    back.hide()
    submit.hide()
    next.show()
    @hostSelector.show()
    @typeSelector.show()
    @mainSettings.hide()
    @setPositions()

  next:->

    {back, next, submit} = @buttons
    back.show()
    submit.show()
    next.hide()
    @hostSelector.hide()
    @typeSelector.hide()
    @mainSettings.show()
    @setPositions()
    hostSelector = @hostSelector.inputs.selector
    typeSelector = @typeSelector.inputs.selector

    for plan, i in @plans when hostSelector.getValue() is i+''
      hostTitle = plan.item.title
    @setTitle "Create a Group <b>[#{typeSelector.getValue()}]</b><b>[#{hostTitle}]</b>"

  createGroup:(callback)->
    formData = {}
    @hostSelector.submit()
    @typeSelector.submit()
    @mainSettings.submit()

    return unless @hostSelector.valid and @typeSelector.valid and @mainSettings.valid

    formData = _.extend formData, @hostSelector.getFormData(), @typeSelector.getFormData(), @mainSettings.getFormData()

    formData.plan = @plans[formData.host]

    log "form for group creation submitted", formData

    if formData.privacy in ['by-invite', 'by-request', 'same-domain']
      formData.requestType = formData.privacy
      formData.privacy     = 'private'

    # Copy account creator's billing information
    KD.remote.api.JRecurlyPlan.getUserAccount (err, data)=>
      warn err
      if err or not data
        data = {}

      # These will go into Recurly module
      delete data.cardNumber
      delete data.cardMonth
      delete data.cardYear
      delete data.cardCV

      modal = createAccountPaymentMethodModal data, (newData, onError, onSuccess)=>
        # These will go into Recurly module
        newData.username    = 'group_unnamed'
        newData.ipAddress   = '0.0.0.0'
        newData.firstName   = 'Group'
        newData.lastName    = 'Unnamed'
        newData.email       = 'group@example.com'
        newData.pin         = 'xxx'
        newData.accountCode = yes

        formData.plan.subscribe newData, (err, account)=>
          if err
            # Show error messages here.
            onError err
          else
            # DONE
            onSuccess()

            console.log account

            KD.remote.api.JGroup.create formData, (err, group)=>
              if err
                callback? err
                new KDNotificationView title: err.message, duration: 1000
              else
                account.attachToGroup group, (err, account)=>
                  console.log "Attach"
                  console.log err
                  console.log account
                  console.log "-------"
                  callback? err, group
                  @getSingleton("groupsController").showGroupCreatedModal group
                  @destroy()


  makeSlug: ->
    form       = @mainSettings
    titleInput = form.inputs.Title
    slugView   = form.inputs.Slug
    slugInput  = form.inputs.HiddenSlug
    slug = KD.utils.slugify titleInput.getValue()
    KD.remote.api.JGroup.suggestUniqueSlug slug, (err, newSlug)->
      if err
        slugView.updatePartial "#{location.protocol}//#{location.host}/"
        slugInput.setValue ''
      else
        slugView.updatePartial "#{location.protocol}//#{location.host}/#{newSlug}"
        slugInput.setValue newSlug

  submit_FOR_PAYMENT_DEPRECATED: ->

    # Copy account creator's billing information
    KD.remote.api.JRecurlyPlan.getUserAccount (err, data)=>
      warn err
      if err or not data
        data = {}

      # These will go into Recurly module
      delete data.cardNumber
      delete data.cardMonth
      delete data.cardYear
      delete data.cardCV

      modal = createAccountPaymentMethodModal data, (newData, onError, onSuccess)=>
        # These will go into Recurly module
        newData.username    = 'group_unnamed'
        newData.ipAddress   = '0.0.0.0'
        newData.firstName   = 'Group'
        newData.lastName    = 'Unnamed'
        newData.email       = 'group@example.com'
        newData.pin         = 'xxx'
        newData.accountCode = yes

        {selector}   = @hostSelector.inputs
        index        = parseInt selector.getValue(), 10

        selectedPlan = @plans[index]
        selectedPlan.subscribe newData, (err, subscription)->
          if err
            # Show error messages here.
            onError()
          else
            # DONE
            console.log "Subscribed user account:", subscription.userCode
            onSuccess()
