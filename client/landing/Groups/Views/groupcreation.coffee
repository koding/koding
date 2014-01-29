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
        testPath       : "groups-create-submit"
        callback       : @bound "createGroup"
      next             :
        title          : "Next"
        style          : "modal-clean-gray"
        type           : "button"
        testPath       : "groups-create-next"
        disabled       : yes
        callback       : @bound "next"
      back             :
        title          : "back"
        style          : "modal-cancel hidden"
        type           : "button"
        callback       : @bound "back"

    super options, data

    @destroy()  unless KD.checkFlag "group-admin"

    @plans = []
    @buttons.next.hide()

    @on 'ready', @buttons.next.enable.bind @buttons.next

  setPositions:->
    super
    $scroller = @$('.kdmodal-content').eq(0)
    $scroller?.scrollTop $scroller[0].scrollHeight

  viewAppended:->

    @addSubView loader = new KDLoaderView
      size          :
        width       : 32
      loaderOptions :
        color       : "#ff9200"

    loader.show()

    vmController = KD.getSingleton('vmController')
    vmController.fetchVMPlans (err, plans) =>

      loader.destroy()
      @buttons.next.show()

      @plans = plans
      { descriptions, hostTypes } = vmController.sanitizeVMPlansForInputs plans

      @addSubView @typeSelector = new KDFormViewWithFields
        cssClass         : "type-selector"
        fields           :
          label          :
            itemClass    : KDCustomHTMLView
            tagName      : 'h2'
            cssClass     : 'heading'
            partial      : "<span>1</span> What will be this group for?"
          selector       :
            name         : "type"
            itemClass    : GroupCreationSelector
            cssClass     : "group-type"
            defaultValue : "project"
            radios       : GROUP_TYPES
            change       : =>
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
        testPath                 : "groups-create-form"
        fields                   :
          "Title"                :
            label                : "Title"
            name                 : "title"
            testPath             : "groups-create-title"
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
            testPath             : "groups-create-desc"
            placeholder          : "Please enter a description for your group here..."
          "Privacy"              :
            label                : "Privacy/Visibility"
            itemClass            : KDSelectBox
            testPath             : "groups-create-privacy"
            type                 : "select"
            name                 : "privacy"
            defaultValue         : "public"
            change               : @bound "privacyChanged"
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
              "DomainAddress"    :
                name             : "domainaddress"
                placeholder      : 'Please enter your domain ...'
                cssClass         : "domain-address"

      @mainSettings.inputs.DomainAddress.hide()

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
          # label          :
          #   itemClass    : KDCustomHTMLView
          #   tagName      : 'h2'
          #   cssClass     : 'heading'
          #   partial      : "<span>2</span> Do you want a shared host for your Group?"
          # sharedHost     :
          #   itemClass    : KDOnOffSwitch
          #   name         : "shared-vm"
          #   defaultValue : no
          #   cssClass     : "shared-vm"
          #   callback     : @bound "hostChanged"
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
            partial       : "<span>2</span> How much resources do you want to allocate to your each user?"
          sharedHost      :
            itemClass     : KDSelectBox
            type          : "select"
            name          : "allocation"
            defaultValue  : "0"
            cssClass      : "allocation"
            change        : @bound "allocationChanged"
            selectOptions : [
              { title : "None",  value : "0" }
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
              <strong>You</strong> will be charged for each member.
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

      @allocationChanged()
      @emit 'ready'

  privacyChanged:->
    {Privacy, DomainAddress} = @mainSettings.inputs
    DomainAddress[if Privacy.getValue() is 'same-domain' then 'show' else 'hide']()

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
    # monthlyFee = (@plans[index].feeAmount / 100).toFixed(2)
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

    if price > 0
      @allocation.fields["Admin approval is required on member purchases"].show()
      @allocation.fields["Allow over-usage"].show()
      desc.show()
    else
      @allocation.fields["Admin approval is required on member purchases"].hide()
      @allocation.fields["Allow over-usage"].hide()
      desc.hide()

    @setPositions()

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

    return unless @hostSelector.valid and @typeSelector.valid and @mainSettings.valid

    formData = _.extend formData, @hostSelector.getFormData(), @typeSelector.getFormData(), @mainSettings.getFormData(), @allocation.getFormData()

    if formData["shared-vm"]
      formData.payment =
        # plan: @plans[formData.host].planCode
        plan: @plans[0].planCode

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
        KD.getSingleton("groupsController").showGroupCreatedModal group
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
