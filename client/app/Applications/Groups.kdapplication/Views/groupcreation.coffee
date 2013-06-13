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
    options.width     ?= 704
    options.overlay   ?= yes
    options.buttons    =
      submit           :
        title          : "Create"
        style          : "modal-clean-gray hidden"
        type           : "button"
        callback       : @bound "createGroup"
      next             :
        title          : "Next"
        style          : "modal-clean-gray"
        type           : "button"
        callback       : @bound "next"
      back             :
        title          : "back"
        style          : "modal-cancel hidden"
        type           : "button"
        callback       : @bound "back"

    super options, data

    @plans = []

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
              # hostSelector = @hostSelector.inputs.selector
              sharedHost   = @hostSelector.inputs.sharedHost

              # @hostSelector?.show()

              # hostSelector.setValue switch typeSelector.getValue()
              #   when "educational" then "4"
              #   when "company"     then "2"
              #   when "project"     then "1"
              #   when "custom"      then "0"

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

    vmController = @getSingleton('vmController')
    vmController.fetchVMPlans (err, plans)=>
      @plans = plans
      {descriptions, hostTypes} = vmController.sanitizeVMPlansForInputs plans

      descPartial = ""
      for d in descriptions
        descPartial += """
          <section>
            <p class='hidden'>
              <i>Good for:</i>
              <span>#{d.meta.goodFor}</span>
              <cite>VMs</cite>
            </p>
            #{d.description}
          </section>"""
      @addSubView @hostSelector = new KDFormViewWithFields
        cssClass         : "host-selector"
        fields           :
          label          :
            itemClass    : KDCustomHTMLView
            tagName      : 'h2'
            cssClass     : 'heading'
            partial      : "<span>2</span> Do you want a shared host for your Group?"
          sharedHost     :
            itemClass    : KDOnOffSwitch
            name         : "shared-vm"
            defaultValue : no
            cssClass     : "shared-vm"
            callback     : @bound "hostChanged"
          # selector    :
          #   name      : "host"
          #   itemClass : HostCreationSelector
          #   cssClass  : "host-type"
          #   radios    : hostTypes
          #   change    : @bound "hostChanged"
          desc        :
            itemClass : KDCustomHTMLView
            cssClass  : "description-field hidden"
            partial   : """<section>
              This VM is going to be shared among all members of your group, admins will receive sudo rights, each member will have a unix user account.
              </section>"""


      @addSubView @allocation = new KDFormViewWithFields
        cssClass          : "allocation"
        fields            :
          label           :
            itemClass     : KDCustomHTMLView
            tagName       : 'h2'
            cssClass      : 'heading'
            partial       : "<span>3</span> How much resources do you want to allocate to your each user?"
          sharedHost      :
            itemClass     : KDSelectBox
            type          : "select"
            name          : "allocation"
            defaultValue  : "10"
            cssClass      : "allocation"
            change        : @bound "allocationChanged"
            selectOptions : [
              { title : "$ 10",  value : "10" }
              { title : "$ 20",  value : "20" }
              { title : "$ 30",  value : "30" }
              { title : "$ 50",  value : "50" }
              { title : "$ 100", value : "100" }
            ]
          desc            :
            itemClass     : KDCustomHTMLView
            cssClass      : "description-field"
            partial       : "<section>
              <p>
                <i>Good for:</i>
                <span class='vm'>2</span>
                <cite>VMs</cite>
              </p>
              Each member of your group can have $<span class='price'>10</span> worth of Koding resources e.g. <span class='vm'>2</span> VMs.
              </section>"
          approval       :
            title        : "Admin approval is required on member purchases"
            itemClass    : KDOnOffSwitch
            name         : "require-approval"
            defaultValue : yes
            cssClass     : "right-aligned"
          overUsage      :
            title        : "Allow over-usage"
            itemClass    : KDOnOffSwitch
            name         : "allow-over-usage"
            defaultValue : yes
            cssClass     : "right-aligned"

      @emit 'ready'

  hostChanged:->
    {next}           = @buttons
    {desc, selector, sharedHost} = @hostSelector.inputs
    descField        = @hostSelector.fields.desc

    if sharedHost.getValue()
      descField.show()
      desc.show()
      # @allocation.show()
    else
      # @allocation.hide()
      descField.hide()
      desc.hide()

    # index      = parseInt selector.getValue(), 10
    # monthlyFee = (@plans[index].feeMonthly/100).toFixed(2)
    index      = 0

    next.show()
    desc.$('section').addClass 'hidden'
    desc.$('section').eq(index).removeClass 'hidden'

    @setPositions()

  allocationChanged:->
    {desc, sharedHost} = @allocation.inputs
    price = parseInt sharedHost.getValue(), 10
    desc.$('section span.vm').text price / 5
    desc.$('section span.price').text price

  back:->

    {back, next, submit} = @buttons
    back.hide()
    submit.hide()
    next.show()
    @hostSelector.show()
    @allocation.show()
    @typeSelector.show()
    @mainSettings.hide()
    @setPositions()

  next:->

    {back, next, submit} = @buttons
    back.show()
    submit.show()
    next.hide()
    @hostSelector.hide()
    @allocation.hide()
    @typeSelector.hide()
    @mainSettings.show()
    @setPositions()
    # hostSelector = @hostSelector.inputs.selector
    # typeSelector = @typeSelector.inputs.selector

    # for plan, i in @plans when hostSelector.getValue() is i+''
    #   hostTitle = plan.item.title
    # @setTitle "Create a Group <b>[#{typeSelector.getValue()}]</b><b>[#{hostTitle}]</b>"

  createGroup:(callback)->
    formData = {}
    @hostSelector.submit()
    @typeSelector.submit()
    @mainSettings.submit()
    @allocation.submit()
    KD.track "Groups", "CreateGroupLastStepOK"

    return unless @hostSelector.valid and @typeSelector.valid and @mainSettings.valid

    formData = _.extend formData, @hostSelector.getFormData(), @typeSelector.getFormData(), @mainSettings.getFormData(), @allocation.getFormData()

    if formData["shared-vm"]
      formData.payment =
        # plan: @plans[formData.host].code
        plan: @plans[0].code

    log "form for group creation submitted", formData

    if formData.privacy in ['by-invite', 'by-request', 'same-domain']
      formData.requestType = formData.privacy
      formData.privacy     = 'private'

    KD.remote.api.JGroup.create formData, (err, group)=>
      if err
        callback? err
        new KDNotificationView title: err.message, duration: 1000
      else
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
