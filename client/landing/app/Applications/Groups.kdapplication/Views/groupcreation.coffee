class GroupCreationModal extends KDModalView

  constructor:(options = {}, data)->

    options.title    or= 'Create a new group'
    options.height   or= 'auto'
    options.cssClass or= "group-admin-modal compose-message-modal admin-kdmodal"
    options.width     ?= 684
    options.overlay   ?= yes

    super options, data

  fetchRecurlyPlans:(callback)->

    # Recurly name: group_vm_*_1
    KD.remote.api.JRecurlyPlan.getPlans "group", "vm", callback
      # plans.forEach (p)->
      #   console.log p.product.item # xs, s, m, l, xl
      #   console.log p.feeMonthly # in cents

    # p.getToken ->
    #   console.log "Emailed PIN"

  charge:(callback)->
    p.subscribe
      pin: '0000'
    , (err, subs)->
      console.log subs

  viewAppended:->

    @addSubView @typeSelector = new KDFormViewWithFields
      fields                   :
        label                  :
          itemClass            : KDCustomHTMLView
          tagName              : 'h2'
          cssClass             : 'heading'
          partial              : "<span>1</span> What will be this group for?"
        selector               :
          name                 : "type"
          itemClass            : GroupCreationSelector
          cssClass             : "group-type"
          radios               : [
            { title : "University/School", value : "educational" }
            { title : "Company",           value : "company" }
            { title : "Project",           value : "project" }
            { title : "Other",             value : "custom" }
          ]
          change               : =>
            # log @typeSelector.inputs.selector.getValue()
            @hostSelector?.show()

    @fetchRecurlyPlans (err, plans)=>

      # fix this one on radios value cannot have some chars and that's why i keep index as the value
      radios = plans.map (plan,i)-> { title : plan.product.item.slice(1), value : i }

      @addSubView @hostSelector = new KDFormViewWithFields
        cssClass                 : 'hidden'
        buttons                  :
          submit                 :
            title                : "Pay & Create the Group"
            style                : "modal-clean-gray hidden"
            type                 : "button"
            callback             : =>

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
            radios               : radios
            change               : =>
              {submit}         = @hostSelector.buttons
              {desc, selector} = @hostSelector.inputs
              descField        = @hostSelector.fields.desc
              descField.show()
              desc.show()
              index      = parseInt selector.getValue(), 10
              monthlyFee = (plans[index].feeMonthly/100).toFixed(2)
              submit.setTitle "Pay & Create the Group for $#{monthlyFee}/mo"
              submit.show()
              desc.$('p').addClass 'hidden'
              desc.$('p').eq(index).removeClass 'hidden'
          desc                   :
            itemClass            : KDCustomHTMLView
            cssClass             : "hidden"
            partial              : """
              <p>For small teams, recommended for up to 10 concurrent developers.</p>
              <p>Small and mid-size development/staging, data processing, encoding, caching.</p>
              <p>Mid-size databases, data processing, encoding, caching.</p>
              <p>High-traffic web applications, ad serving, batch processing, video encoding, distributed analytics, high-energy physics, genome analysis, and computational fluid dynamics.</p>
              <p>High performance databases, distributed memory caches, in-memory analytics, genome assembly and analysis, and larger deployments</p>
              """

