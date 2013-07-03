class VirtualizationController extends KDController

  constructor:->
    super

    @kc = KD.getSingleton("kiteController")
    @dialogIsOpen = no
    @resetVMData()
    (KD.getSingleton 'mainController').once 'AppIsReady', => @fetchVMs()
    @on 'VMListChanged', @bound 'resetVMData'

  run:(vm, command, callback)->
    # KD.requireMembership
    #   callback : =>
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
      # onFailMsg : "Login required to use VMs"  unless command is 'vm.info'
      # onFail    : =>
      #   unless command is 'vm.info' then callback yes
      #   else callback null, state: 'STOPPED'
      # silence   : yes

    if "string" is typeof options
      command = options
      options =
        withArgs : command

    @fetchDefaultVmName (defaultVmName)=>
      vmName = if options.vmName then options.vmName else defaultVmName
      unless vmName
        return callback message: 'There is no VM for this account.'
      options.correlationName = vmName
      @kc.run options, callback

  _runWraper:(command, vm, callback)->
    [callback, vm] = [vm, callback]  unless 'string' is typeof vm
    @fetchDefaultVmName (defaultVm)=>
      vm or= defaultVm
      return  unless vm
      # KD.requireMembership
      #   callback : =>
      @askForApprove command, (approved)=>
        if approved
          cb = unless command is 'vm.info' then @_cbWrapper vm, callback \
               else callback
          @run
            kiteName : 'os'
            method   : command
            vmName   : vm
          , cb
        else unless command is 'vm.info' then @info vm
        # onFailMsg : "Login required to use VMs"  unless command is 'vm.info'
        # onFail    : =>
        #   unless command is 'vm.info' then callback yes
        #   else callback null, state: 'STOPPED'
        # silence   : yes

  start:(vm, callback)->
    @_runWraper 'vm.start', vm, callback

  stop:(vm, callback)->
    @_runWraper 'vm.shutdown', vm, callback

  halt:(vm, callback)->
    @_runWraper 'vm.stop', vm, callback

  reinitialize:(vm, callback)->
    @_runWraper 'vm.reinitialize', vm, callback

  remove: do->

    deleteVM = (vm, cb)->
      KD.remote.api.JVM.removeByHostname vm, (err)->
        return cb err  if err
        KD.getSingleton("finderController").unmountVm vm
        KD.getSingleton("vmController").emit 'VMListChanged'
        cb null

    (vm, callback=noop)->
      KD.remote.api.JVM.fetchVMInfo vm, (err, vmInfo)=>
        if vmInfo
          if vmInfo.planCode is 'free'
            @askForApprove 'vm.remove', (state)->
              return callback null  unless state
              deleteVM vm, callback
          else
            paymentController = KD.getSingleton('paymentController')
            paymentController.deleteVM vmInfo, (state)->
              return callback null  unless state
              deleteVM vm, callback
        else
          callback message: "No such VM!"

  info:(vm, callback=noop)->
    [callback, vm] = [vm, callback]  unless 'string' is typeof vm
    @fetchDefaultVmName (defaultVm)=>
      vm or= defaultVm
      @_runWraper 'vm.info', vm, (err, info)=>
        warn "[VM-#{vm}]", err  if err
        @emit 'StateChanged', err, vm, info
        callback? err, vm, info
      , no

  hasThisVM:(vmTemplate, vms)->
    for i in [0..vms.length]  when ("#{vmTemplate}".replace '%d', i) in vms
      return ("#{vmTemplate}".replace '%d', i)
    return no

  fetchDefaultVmName:(callback=noop, force=no)->
    if @defaultVmName and not force
      return callback @defaultVmName

    {entryPoint}   = KD.config
    currentGroup   = if entryPoint?.type is 'group' then entryPoint.slug
    currentGroup or= 'koding'

    @fetchVMs (err, vms)=>
      if err or not vms
        return callback null

      # If there is just one return it
      if vms.length is 1
        return callback @defaultVmName = vms.first

      # Check for personal VMs in current group
      vmName = @hasThisVM("vm-%d.#{KD.nick()}.#{currentGroup}.kd.io", vms)
      return callback @defaultVmName = vmName  if vmName

      # Check for shared VMs in current group
      vmName = @hasThisVM("shared-%d.#{currentGroup}.kd.io", vms)
      return callback @defaultVmName = vmName  if vmName

      # Check for personal VMs in Koding group
      vmName = @hasThisVM("vm-%d.#{KD.nick()}.koding.kd.io", vms)
      return callback @defaultVmName = vmName  if vmName

      callback @defaultVmName = vms.first

  createGroupVM:(type='user', planCode, callback=->)->
    vmCreateCallback = (err, vm)->
      vmController = KD.getSingleton('vmController')

      if err
        warn err
        return new KDNotificationView
          title : err.message or "Something bad happened while creating VM"
      else
        KD.getSingleton("finderController").mountVm vm.hostnameAlias
        vmController.emit 'VMListChanged'
        vmController.showVMDetails vm

    defaultVMOptions = {planCode}
    group = KD.getSingleton("groupsController").getCurrentGroup()
    group.createVM {type, planCode}, vmCreateCallback

  fetchVMs:(callback)->
    return callback null, @vms  if @vms.length > 0
    KD.remote.api.JVM.fetchVms (err, vms)=>
      @vms = vms  unless err
      callback? err, vms

  fetchGroupVMs:(callback)->
    return callback null, @groupVms  if @groupVms.length > 0
    KD.remote.api.JVM.fetchVmsByContext (err, vms)=>
      @groupVms = vms  unless err
      callback? err, vms

  fetchVMDomains:(vmName, callback)->
    domains = @vmDomains[vmName]
    return callback null, domains  if domains
    KD.remote.api.JVM.fetchDomains vmName, (err, domains=[])=>
      return callback err, domains  if err
      callback null, @vmDomains[vmName] = domains.sort (x, y)-> x.length>y.length

  resetVMData:->
    @vms = @groupVms = []
    @defaultVmName = null
    @vmDomains = {}

  # fixme GG!
  fetchTotalVMCount:(callback)->
    KD.remote.api.JVM.count (err, count)->
      if err then warn err
      callback null, count ? "0"

  # fixme GG!
  fetchTotalLoC:(callback)->
    callback null, "0"

  _cbWrapper:(vm, callback)->
    return (rest...)=>
      @info vm, callback? rest...

  hasDefaultVM:(callback)->
    # Default VM should be the personal vm in Koding group
    @fetchVMs (err, vms)->
      if err
        warn "An error occured while fetching VMs:", err
        return callback yes

      # Check if there is at least one personal vm from koding group
      for vm in vms
        if (vm.indexOf 'vm-') is 0 and (vm.indexOf 'koding.kd.io') > -1
          return callback yes

      callback no

  createDefaultVM:->
    @hasDefaultVM (state)->
      return warn 'Default VM already exists.'  if state
      KD.remote.cacheable 'koding', (err, group)->
        if err or not group?.length
          return warn err
        koding = group.first
        koding.createVM
          planCode : 'free'
          type     : 'user'
        , (err)->
          unless err
            vmController = KD.getSingleton('vmController')
            vmController.fetchDefaultVmName (defaultVmName)->
              vmController.emit 'VMListChanged'
              KD.getSingleton('finderController').mountVm defaultVmName
          else warn err

  createNewVM:->
    @hasDefaultVM (state)=>
      if state then @createPaidVM() else @createDefaultVM()

  showVMDetails: (vm)->
    vmName = vm.hostnameAlias
    url    = "https://#{vm.hostnameAlias}"

    content = """
                <div class="item">
                  <span class="title">Name:</span>
                  <span class="value">#{vmName}</span>
                </div>
                <div class="item">
                  <span class="title">Hostname:</span>
                  <span class="value">
                    <a target="_new" href="#{url}">#{url}</a>
                  </span>
                </div>
              """

    modal           = new KDModalView
      title         : "Your VM is ready"
      content       : "<div class='modalformline'>#{content}</div>"
      cssClass      : "vm-details-modal"
      overlay       : yes
      buttons       :
        OK          :
          title     : "OK"
          cssClass  : "modal-clean-green"
          callback  : =>
            modal.destroy()

  createPaidVM:->
    return  if @dialogIsOpen

    vmController        = KD.getSingleton('vmController')
    paymentController   = KD.getSingleton('paymentController')
    canCreateSharedVM   = "owner" in KD.config.roles or "admin" in KD.config.roles
    canCreatePersonalVM = "member" in KD.config.roles

    group = KD.getSingleton("groupsController").getGroupSlug()

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
                paymentController.confirmPayment formData.type, @paymentPlans[formData.host], ->
                  modal.destroy()
              buttons               :
                user                :
                  title             : "Create a <b>Personal</b> VM"
                  style             : "modal-clean-gray"
                  type              : "submit"
                  loader            :
                    color           : "#ffffff"
                    diameter        : 12
                  callback          : ->
                    form = modal.modalTabs.forms["Create VM"]
                    form.inputs.type.setValue "user"
                group               :
                  title             : "Create a <b>Shared</b> VM"
                  style             : "modal-clean-gray hidden"
                  type              : "submit"
                  loader            :
                    color           : "#ffffff"
                    diameter        : 12
                  callback          : ->
                    form = modal.modalTabs.forms["Create VM"]
                    form.inputs.type.setValue "group"
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
                  defaultValue      : 0
                  validate          :
                    rules           :
                      required      : yes
                    messages        :
                      required      : "Please select a VM type!"
                  change            : =>
                    # form = modal.modalTabs.forms["Create VM"]
                    # {desc, selector} = form.inputs
                    # descField        = form.fields.desc
                    # descField.show()
                    # desc.show()
                    # index      = (parseInt selector.getValue(), 10) or 0
                    # monthlyFee = (@paymentPlans[index].feeMonthly/100).toFixed(2)
                    # desc.$('section').addClass 'hidden'
                    # desc.$('section').eq(index).removeClass 'hidden'
                    # modal.setPositions()
                desc                :
                  itemClass         : KDCustomHTMLView
                  cssClass          : "description-field hidden"
                  partial           : descPartial
                type                :
                  name              : "type"
                  type              : "hidden"

      if canCreateSharedVM
        modal.modalTabs.forms["Create VM"].buttons.group.show()

      @dialogIsOpen = yes
      modal.once 'KDModalViewDestroyed', => @dialogIsOpen = no

      form = modal.modalTabs.forms["Create VM"]

      hideLoaders = ->
        {group, user} = form.buttons
        user.hideLoader()
        group.hideLoader()

      vmController.on "PaymentModalDestroyed", hideLoaders
      form.on "FormValidationFailed", hideLoaders


  askForApprove:(command, callback)->

    switch command
      when 'vm.stop', 'vm.shutdown'
        content = """<p>Turning off your VM will <b>stop</b> running Terminal
                     instances and all running proccesess that you have on
                     your VM. Do you want to continue?</p>"""
        button  =
          title : "Turn off"
          style : "modal-clean-red"

      when 'vm.reinitialize'
        content = """<p>Re-initializing your VM will <b>reset</b> all of your
                     settings that you've done in root filesystem. This
                     process will not remove any of your files under your
                     home directory. Do you want to continue?</p>"""
        button  =
          title : "Re-initialize"
          style : "modal-clean-red"

      when 'vm.remove'
        content = """<p>Removing this VM will <b>destroy</b> all the data in
                     this VM including all other users in filesystem. <b>Please
                     be careful this process cannot be undone.</b></p>

                     <p>Do you want to continue?</p>"""
        button  =
          title : "Remove VM"
          style : "modal-clean-red"

      else
        return callback yes

    return  if @dialogIsOpen

    modal = new KDModalView
      title          : "Approval required"
      content        : "<div class='modalformline'>#{content}</div>"
      cssClass       : "vm-approval"
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
                  KD.getSingleton("appManager").open appName
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
