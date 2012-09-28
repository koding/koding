class KiteSelectorModal extends KDModalView

  constructor: (options = {}, data) ->

    options.title = "Select kites"

    super options, data

    @putTable()

  sanitizeHosts = (hosts)->
    hosts.map (host)->
      value : host
      title : host

  kiteIsChanged:(kiteName, value)->
    KD.whoami().setKiteConnection kiteName, value

  createNewKiteModal:->
    # TODO: write real descriptions for these:
    descriptions =
      'Load Balancing Strategy':
        none              : 'Single node'
        roundrobin        : 'Describe round robin'
        leastconnections  : 'Describe least connections'
        fanout            : 'Describe fanout'
        globalip          : 'Describe global ip'
        random            : 'Describe random'
    loadBalancerDescription = new KDCustomHTMLView
      tagName     : 'span'
      partial     : descriptions['Load Balancing Strategy'].none
    modal = new KDModalViewWithForms
      title : 'Create a kite service'
      tabs  :
        navigable             : yes
        goToNextFormOnSubmit  : no
        forms                 :
          "Create a service"  :
            callback          : =>
              kiteName = form.getData().kiteName
              KD.remote.api.JKiteCluster.count {kiteName}, (err, count)=>
                unless count is 0
                  new KDNotificationView
                    title: 'That kite name is not available; please choose another.'
                else
                  @createNewPlanModal
                    kiteData: form.getData()
                  modal.destroy()
            buttons           :
              "Create a plan" :
                title         : 'Create a plan'
                style         : "modal-clean-gray"
                type          : "submit"
                loader        :
                  color       : "#444444"
                  diameter    : 12
            fields            :
              'Kite Name'     :
                label         : "Kite name"
                name          : 'kiteName'
                itemClass     : KDInputView
                validate      :
                  rules       :
                    bareword  : (input)->
                      input.setValidationResult /^\w+$/.test input.getValue()
                  messages    :
                    bareword  : 'Kite name cannot have spaces or punctuation.'
              'Load Balancing Strategy' :
                label         : "Load balancing strategy"
                itemClass     : KDSelectBox
                type          : "select"
                name          : "loadBalancing"
                defaultValue  : "none"
                selectOptions : [
                  { title : "None",               value : "none" }
                  { title : "Round-robin",        value : "roundrobin" }
                  { title : "Least connections",  value : "leastconnections" }
                  { title : "Fanout",             value : "fanout" }
                  { title : "Global IP",          value : "globalip" }
                  { title : "Random",             value : "random" }
                ]
                callback: (value)-> loadBalancerDescription.updatePartial descriptions['Load Balancing Strategy'][value]
    form = modal.modalTabs.forms["Create a service"]
    form.fields["Load Balancing Strategy"].addSubView loadBalancerDescription

  createNewPlanModal:(accumulator)->
    collectData =->
      accumulator.planData ?= []
      accumulator.planData.push(
        modal.modalTabs.forms['Create a plan'].getData()
      )
    descriptions =
      Type        :
        free      : 'Anyone can use this plan'
        paid      : 'Users must pay for this plan'
        protected : 'Users must be invited to use this plan'
        custom    : 'You will define your own business logic for authenticating users'
      'Interval Unit':
        day       : 'days'
        month     : 'months'
    planTypeDescription = new KDCustomHTMLView
      tagName     : 'span'
      partial     : descriptions.Type.free
    planIdDescription = new KDCustomHTMLView
      tagName     : 'span'
      partial     : "This can be any value.  You will use it for your own business logic."
    intervalUnitDescription = new KDCustomHTMLView
      tagName     : 'span'
      partial     : descriptions['Interval Unit'].day
    unitAmountDescription = new KDCustomHTMLView
      tagName     : 'span'
      partial     : 'USD'
    paidOnlyFields = ['Interval Unit','Interval Length','Unit Amount']
    modal = new KDModalViewWithForms
      title : 'Create a kite plan'
      tabs                    :
        navigable             : yes
        goToNextFormOnSubmit  : no
        # callback              : (formOutput)-> log formOutput
        forms                 :
          "Create a plan"     :
            callback          : =>
              collectData()
              KD.remote.api.JKiteCluster.create accumulator, (err, cluster)=>
                if err
                  new KDNotificationView
                    title : err.message
                else
                  @createClusterIsCreatedModal cluster
                modal.destroy()
            buttons           :
              "Create another plan":
                title         : "Create another plan"
                style         : "modal-clean-gray"
                type          : "button"
                loader        :
                  color       : "#444444"
                  diameter    : 12
                callback      : =>
                  collectData()
                  @createNewPlanModal accumulator
                  modal.destroy()
              "All done"      :
                title         : "All done"
                style         : "modal-clean-gray"
                type          : "submit"
                loader        :
                  color       : "#444444"
                  diameter    : 12
            fields            :
              Title           :
                label         : "Plan Name"
                itemClass     : KDInputView
                name          : 'planName'
              'Plan ID'       :
                label         : "Plan Id"
                itemClass     : KDInputView
                name          : 'planId'
              Type            :
                label         : "Type"
                itemClass     : KDSelectBox
                type          : "select"
                name          : "type"
                defaultValue  : "free"
                selectOptions : [
                  { title : "Free",       value : "free" }
                  { title : "Paid",       value : "paid" }
                  { title : "Protected",  value : "protected" }
                  { title : "Custom",     value : "custom" }
                ]
                callback: (value)->
                  paidOnlyFields.forEach(
                    if value is 'paid'
                      (name)-> form.fields[name].show()
                    else
                      (name)-> form.fields[name].hide()
                  )
                  planTypeDescription.updatePartial descriptions.Type[value]
              'Interval Unit' :
                label         : "Interval unit"
                itemClass     : KDSelectBox
                type          : "select"
                name          : "intervalUnit"
                defaultValue  : "day"
                selectOptions : [
                  { title : "Daily",    value : "day" }
                  { title : "Monthly",  value : "month" }
                ]
                callback: (value)-> intervalUnitDescription.updatePartial descriptions['Interval Unit'][value]
              'Interval Length' :
                label         : "Interval length"
                itemClass     : KDInputView
                name          : "intervalLength"
                defaultValue  : 1
                attributes      :
                  valueAsNumber : yes
                  size          : 3
                  min           : 1
              'Unit Amount' :
                label         : "Unit amount"
                itemClass     : KDInputView
                name          : "unitAmount"
                defaultValue  : "1.00"
                attributes      :
                  valueAsNumber : yes
                  size          : 3
    form = modal.modalTabs.forms["Create a plan"]
    form.fields.Type.addSubView planTypeDescription
    form.fields['Plan ID'].addSubView planIdDescription
    form.fields['Interval Length'].addSubView intervalUnitDescription
    form.fields['Unit Amount'].addSubView unitAmountDescription
    paidOnlyFields.forEach (name)-> form.fields[name].hide()

  createClusterIsCreatedModal:(cluster)->
    modal = new KDModalView
      title   : "Kite service is created"
      content :
        """
        <p>The service was created!</p>
        <p>Kite name: <strong>#{cluster.getAt('kiteName')}</strong></p>
        <p>Service key: <strong>#{cluster.getAt('serviceKey')}</strong></p>
        <p>Keep it safe, and change it often!</p>
        """

  putTable:->

    KD.whoami().fetchAllKiteClusters (err, clusters)=>
      if err
        new KDNotificationView
          title : err.message
        @destroy()
      else
        clusters.forEach (cluster)=>
          {kiteName, kites, currentKiteUri} = cluster

          selectOptions = sanitizeHosts kites if kites

          @addSubView field = new KDView
            cssClass : "modalformline"

          field.addSubView new KDLabelView
            title    : kiteName

          field.addSubView new KDSelectBox
            selectOptions : selectOptions
            cssClass      : "fr"
            defaultValue  : currentKiteUri
            callback      : (value)=> @kiteIsChanged kiteName, value

        @addSubView new KDButtonView
          style     : "clean-gray savebtn"
          title     : "Create a kite service"
          callback  : =>
            @createNewKiteModal()
            @destroy()
