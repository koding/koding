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
    options.cssClass or= "group-admin-modal compose-message-modal admin-kdmodal"
    options.width     ?= 684
    options.overlay   ?= yes

    super options, data

    @plans = []

  fetchRecurlyPlans:(callback)-> KD.remote.api.JRecurlyPlan.getPlans "group", "vm", callback

  charge:(plan, callback)-> plan.subscribe { pin: '0000' }, callback

  viewAppended:->

    @addSubView @typeSelector = new KDFormViewWithFields
      fields         :
        label        :
          itemClass  : KDCustomHTMLView
          tagName    : 'h2'
          cssClass   : 'heading'
          partial    : "<span>1</span> What will be this group for?"
        selector     :
          name       : "type"
          itemClass  : GroupCreationSelector
          cssClass   : "group-type"
          radios     : GROUP_TYPES
          change     : =>
            @hostSelector?.show()
            @setPositions()

    @fetchRecurlyPlans (err, plans)=>

      plans.sort (a, b)-> a.feeMonthly - b.feeMonthly
      @plans = plans  if plans

      # fix this one on radios value cannot have some chars and that's why i keep index as the value
      hostTypes    = plans.map (plan, i)-> { title : plan.product.item.slice(1), value : i }
      descriptions = plans.map (plan, i)->
        res = null
        try
          res = JSON.parse plan.desc.replace /&quot;/g, '"'
        catch e
          res =
            title     : ""
            desc      : plan.desc
            meta      :
              goodFor : 0
        return res

      log ">>>>", descriptions

      @addSubView @hostSelector = new KDFormViewWithFields
        cssClass                 : 'hidden'
        buttons                  :
          submit                 :
            title                : "Pay & Create the Group"
            style                : "modal-clean-gray hidden"
            type                 : "button"
            callback             : @bound "submit"
        fields                   :
          label                  :
            itemClass            : KDCustomHTMLView
            tagName              : 'h2'
            cssClass             : 'heading'
            partial              : "<span>2</span> How big should the host server be?"
          selector               :
            name                 : "host"
            itemClass            : GroupCreationSelector
            cssClass             : "host-type"
            radios               : hostTypes
            change               : @bound "hostChanged"
          desc                   :
            itemClass            : KDCustomHTMLView
            cssClass             : "hidden"
            partial              : """
              <p></p>
              <p></p>
              <p></p>
              <p></p>
              <p></p>
              """




  hostChanged:->
    {submit}         = @hostSelector.buttons
    {desc, selector} = @hostSelector.inputs
    descField        = @hostSelector.fields.desc

    descField.show()
    desc.show()

    index      = parseInt selector.getValue(), 10
    monthlyFee = (@plans[index].feeMonthly/100).toFixed(2)

    submit.setTitle "Pay & Create the Group for $#{monthlyFee}/mo"
    submit.show()
    desc.$('p').addClass 'hidden'
    desc.$('p').eq(index).removeClass 'hidden'

    @setPositions()

  submit:=>


              # Copy account creator's billing information
              KD.remote.api.JRecurlyPlan.getUserAccount (err, data)=>
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

                  selectedPlan = plans[index]
                  selectedPlan.subscribe newData, (err, subscription)->
                    if err
                      # Show error messages here.
                      onError()
                    else
                      # DONE
                      console.log "Subscribed user account:", subscription.userCode
                      onSuccess()

