class VirtualizationController extends KDController

  constructor:->
    super

    @kc = KD.singletons.kiteController
    @dialogIsOpen = no
    @resetVMData()

  run:(vm, command, callback)->
    KD.requireMembership
      callback : =>
        @askForApprove command, (approved)=>
          if approved
            cb = unless command is 'vm.info' then @_cbWrapper vm, callback \
                 else callback
            @kc.run
              kiteName : 'os'
              method   : command
              vmName   : vm
            , cb
          else unless command is 'vm.info' then @info vm
      onFailMsg : "Login required to use VMs"  unless command is 'vm.info'
      onFail    : =>
        unless command is 'vm.info' then callback yes
        else callback null, state: 'STOPPED'
      silence   : yes

  _runWraper:(command, vm, callback)->
    [callback, vm] = [vm, callback]  unless 'string' is typeof vm
    vm or= @getDefaultVmName vm
    @run vm, command, callback

  start:(vm, callback)->
    @_runWraper 'vm.start', vm, callback

  stop:(vm, callback)->
    @_runWraper 'vm.shutdown', vm, callback

  halt:(vm, callback)->
    @_runWraper 'vm.stop', vm, callback

  reinitialize:(vm, callback)->
    @_runWraper 'vm.reinitialize', vm, callback

  remove:(vm, callback=noop)->
    @stop vm, (err)=>
      return callback err  if err
      @askForApprove 'vm.remove', (state)->
        return callback null  unless state
        KD.remote.api.JVM.removeByName vm, (err)->
          return callback err  if err
          KD.singletons.finderController.unmountVm vm
          KD.singletons.vmController.emit 'VMListChanged'
          callback null

  info:(vm, callback)->
    [callback, vm] = [vm, callback]  unless 'string' is typeof vm
    vm or= @getDefaultVmName vm
    @_runWraper 'vm.info', vm, (err, info)=>
      warn "[VM-#{vm}]", err  if err
      @emit 'StateChanged', err, vm, info
      callback? err, vm, info
    , no

  getDefaultVmName:->
    {entryPoint} = KD.config
    currentGroup = if entryPoint?.type is 'group' then entryPoint.slug
    if not currentGroup or currentGroup is 'koding' then "koding~#{KD.nick()}"
    else currentGroup

  createGroupVM:(type='personal', planCode, callback)->
    defaultVMOptions =
      planCode       : planCode
    group = KD.singletons.groupsController.getCurrentGroup()

    group.createVM {type}, callback

  fetchVMs:(callback)->
    return callback null, @vms  if @vms.length > 0
    KD.remote.api.JVM.fetchVms (err, vms)=>
      @vms = vms  unless err
      callback err, vms

  fetchGroupVMs:(callback)->
    return callback null, @groupVms  if @groupVms.length > 0
    KD.remote.api.JVM.fetchVmsByContext (err, vms)=>
      @groupVms = vms  unless err
      callback err, vms

  resetVMData:->
    @vms = @groupVms = []

  # fixme GG!
  fetchTotalVMCount:(callback)->
    callback null, "0"

  # fixme GG!
  fetchTotalLoC:(callback)->
    callback null, "0"

  _cbWrapper:(vm, callback)->
    return (rest...)=>
      @info vm, callback? rest...

  createNewVM:->
    return  if @dialogIsOpen
    vmController        = @getSingleton('vmController')
    canCreateSharedVM   = "owner" in KD.config.roles or "admin" in KD.config.roles
    canCreatePersonalVM = "member" in KD.config.roles


    # Take this to a better place, possibly to payment controller.
    makePayment = (type, plan, callback)->
      planCode = plan.code
      if type is 'shared'
        group = KD.singletons.groupsController.getCurrentGroup()
        group.checkPayment (err, payments)->
          if err or payments.length is 0

            # Copy account creator's billing information
            KD.remote.api.JRecurlyPlan.getUserAccount (err, data)->
              warn err
              if err or not data
                data = {}

              # These will go into Recurly module
              delete data.cardNumber
              delete data.cardMonth
              delete data.cardYear
              delete data.cardCV

              paymentModal = createAccountPaymentMethodModal data, (newData, onError, onSuccess)->
                newData.plan = planCode
                group.makePayment newData, (err, subscription)->
                  if err
                    onError err
                  else
                    vmController.createGroupVM type, planCode, vmCreateCallback
                    onSuccess()
                    callback()
              paymentModal.on "KDModalViewDestroyed", -> vmController.emit "PaymentModalDestroyed"
          else
            group.updatePayment {plan: planCode}, (err, subscription)->
              vmController.createGroupVM type, planCode, vmCreateCallback
              callback()
      else
        _createUserVM = (cb)->
          KD.remote.api.JRecurlyPlan.getPlanWithCode planCode, (err, plan)->
            plan.subscribe {}, (err, subscription)->
              return cb err  if cb and err
              vmController.createGroupVM type, planCode, vmCreateCallback
              cb?()
        KD.remote.api.JRecurlyPlan.getUserAccount (err, account)->
          if err
            paymentModal = createAccountPaymentMethodModal {}, (newData, onError, onSuccess)->
              newData.plan = planCode
              KD.remote.api.JRecurlyPlan.setUserAccount newData, (err, result)->
                if err
                  onError err
                else
                  onSuccess result
                  _createUserVM callback
            paymentModal.on "KDModalViewDestroyed", -> vmController.emit "PaymentModalDestroyed"
          else
            _createUserVM callback

    vmCreateCallback  = (err, vm)->
      if err
        warn err
        return new KDNotificationView
          title : err.message or "Something bad happened while creating VM"
      else
        KD.singletons.finderController.mountVm vm.name
        vmController.emit 'VMListChanged'
      paymentModal?.destroy()

    group = KD.singletons.groupsController.getGroupSlug()

    if canCreateSharedVM
      content = """You can create a <b>Personal</b> or <b>Shared</b> VM for
                   <b>#{group}</b>. If you prefer to create a shared VM, all
                   members in <b>#{group}</b> will be able to use that VM.
                """
    else if canCreatePersonalVM
      content = """You can create a <b>Personal</b> VM in <b>#{group}</b>."""
    else
      return new KDNotificationView
        title : "You are not authorized to create VMs in #{group} group"

    vmController.fetchVMPlans (err, plans)=>
      @paymentPlans = plans
      {descriptions, hostTypes} = vmController.sanitizeVMPlansForInputs plans
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

      modal = new KDModalViewWithForms
        title                       : "Create a new VM"
        cssClass                    : "group-creation-modal"
        height                      : "auto"
        width                       : 500
        overlay                     : yes
        tabs                        :
          navigable                 : no
          forms                     :
            "Create VM"             :
              callback              : (formData)=>

                form                = modal.modalTabs.forms["Create VM"]
                {personal, shared}  = form.buttons

                makePayment formData.type, @paymentPlans[formData.host], ->
                  modal.destroy()
              buttons               :
                personal            :
                  title             : "Create a <b>Personal</b> VM"
                  style             : "modal-clean-gray"
                  type              : "submit"
                  loader            :
                    color           : "#ffffff"
                    diameter        : 12
                  callback          : ->
                    form = modal.modalTabs.forms["Create VM"]
                    form.inputs.type.setValue "personal"
                shared              :
                  title             : "Create a <b>Shared</b> VM"
                  style             : "modal-clean-gray hidden"
                  type              : "submit"
                  loader            :
                    color           : "#ffffff"
                    diameter        : 12
                  callback          : ->
                    form = modal.modalTabs.forms["Create VM"]
                    form.inputs.type.setValue "shared"
                cancel              :
                  style             : "modal-cancel"
                  callback          : -> modal.destroy()
              fields                :
                "intro"             :
                  itemClass         : KDCustomHTMLView
                  partial           : "<p>#{content}</p>"
                selector            :
                  name              : "host"
                  itemClass         : HostCreationSelector
                  cssClass          : "host-type"
                  radios            : hostTypes
                  validate          :
                    rules           :
                      required      : yes
                    messages        :
                      required      : "Please select a VM type!"
                  change            : =>
                    form = modal.modalTabs.forms["Create VM"]
                    {desc, selector} = form.inputs
                    descField        = form.fields.desc
                    descField.show()
                    desc.show()
                    index      = parseInt selector.getValue(), 10
                    monthlyFee = (@paymentPlans[index].feeMonthly/100).toFixed(2)
                    desc.$('section').addClass 'hidden'
                    desc.$('section').eq(index).removeClass 'hidden'
                    modal.setPositions()
                desc                :
                  itemClass         : KDCustomHTMLView
                  cssClass          : "description-field hidden"
                  partial           : descPartial
                type                :
                  name              : "type"
                  type              : "hidden"



      if canCreateSharedVM
        modal.modalTabs.forms["Create VM"].buttons.shared.show()

      @dialogIsOpen = yes
      modal.once 'KDModalViewDestroyed', => @dialogIsOpen = no

      form = modal.modalTabs.forms["Create VM"]

      hideLoaders = ->
        {personal, shared} = form.buttons
        personal.hideLoader()
        shared.hideLoader()

      vmController.on "PaymentModalDestroyed", hideLoaders
      form.on "FormValidationFailed", hideLoaders

  askForApprove:(command, callback)->

    switch command
      when 'vm.stop', 'vm.shutdown'
        content = """Turning off your VM will <b>stop</b> running Terminal
                     instances and all running proccesess that you have on
                     your VM. Do you want to continue?"""
        button  =
          title : "Turn off"
          style : "modal-clean-red"

      when 'vm.reinitialize'
        content = """Re-initializing your VM will <b>reset</b> all of your
                     settings that you've done in root filesystem. This
                     process will not remove any of your files under your
                     home directory. Do you want to continue?"""
        button  =
          title : "Re-initialize"
          style : "modal-clean-red"

      when 'vm.remove'
        content = """Removing this VM will <b>destroy</b> all the data in
                     this VM including all other users in filesystem.
                     <b>Please be careful this process cannot be undone</b>.
                     Do you want to continue?"""
        button  =
          title : "Remove VM"
          style : "modal-clean-red"

      else
        return callback yes

    return  if @dialogIsOpen

    modal = new KDModalView
      title          : "Approval required"
      content        : "<div class='modalformline'><p>#{content}</p></div>"
      height         : "auto"
      overlay        : yes
      buttons        :
        Action       :
          title      : button.title
          style      : button.style
          callback   : ->
            modal.destroy()
            callback yes
        Cancel       :
          style      : "modal-clean-gray"
          callback   : ->
            modal.destroy()
            callback no

    modal.once 'KDModalViewDestroyed', -> callback no

    @dialogIsOpen = yes
    modal.once 'KDModalViewDestroyed', => @dialogIsOpen = no

  askToTurnOn:(appName='', callback)->

    return  if @dialogIsOpen

    content = """To #{if appName then 'run' else 'do this'} <b>#{appName}</b>
                 you need to turn on your VM first, you can do that by
                 clicking '<b>Turn ON VM</b>' button below."""

    modal = new KDModalView
      title          : "Your VM is turned off"
      content        : "<div class='modalformline'><p>#{content}</p></div>"
      height         : "auto"
      overlay        : yes
      buttons        :
        'Turn ON VM' :
          style      : "modal-clean-green"
          callback   : =>
            @start =>
              modal.destroy()
              if appName
                @once 'StateChanged', ->
                  appManager.open appName
        Cancel       :
          style      : "modal-clean-gray"
          callback   : ->
            modal.destroy()
            callback?()

    modal.once 'KDModalViewDestroyed', -> callback?()

    @dialogIsOpen = yes
    modal.once 'KDModalViewDestroyed', => @dialogIsOpen = no

  # there may be a better place for these who methods below - SY

  fetchVMPlans:(callback)->
    KD.remote.api.JRecurlyPlan.getPlans "group", "vm", (err, plans)=>
      if err then warn err
      else if plans
        plans.sort (a, b)-> a.feeMonthly - b.feeMonthly

      callback err, plans

  sanitizeVMPlansForInputs:(plans)->
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

    return {descriptions, hostTypes}
