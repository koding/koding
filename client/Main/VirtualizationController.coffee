class VirtualizationController extends KDController

  constructor:->
    super

    @kc = KD.getSingleton("kiteController")
    @resetVMData()

    KD.getSingleton('mainController')
      .once('AppIsReady', @bound 'fetchVMs')
      .on('AccountChanged', => @emit 'VMListChanged')

    @on 'VMListChanged', @bound 'resetVMData'


  run:(options, callback = noop)->
    [callback, options] = [options, callback]  unless callback
    options ?= {}
    if "string" is typeof options
      command = options
      options =
        withArgs : command

    @fetchVmName options, (err, vmName) =>
      return callback err  if err?
      options.correlationName = vmName
      @fetchRegion vmName, (region)=>
        options.kiteName = "os-#{region}"
        @kc.run options, (rest...) ->
          # log rest...
          callback rest...

  _runWrapper:(command, vm, callback)->
    [callback, vm] = [vm, callback]  if vm and 'string' isnt typeof vm
    @fetchDefaultVmName (defaultVm)=>
      vm or= defaultVm
      return  unless vm
      @askForApprove command, (approved)=>
        if approved
          cb =
            unless command is 'vm.info'
            then @_cbWrapper vm, callback
            else callback
          @run
            method   : command
            vmName   : vm
          , cb
        else unless command is 'vm.info' then @info vm

  resizeDisk:(vm, callback)->
    @_runWrapper 'vm.resizeDisk', vm, callback

  start:(vm, callback)->
    @_runWrapper 'vm.start', vm, callback

  stop:(vm, callback)->
    @_runWrapper 'vm.shutdown', vm, callback

  halt:(vm, callback)->
    @_runWrapper 'vm.stop', vm, callback

  reinitialize:(vm, callback)->
    @_runWrapper 'vm.reinitialize', vm, callback

  fetchVmInfo: (vm, callback) ->
    { JVM } = KD.remote.api

    JVM.fetchVmInfo vm, callback

  confirmVmDeletion: (vmInfo, callback = (->)) ->
    { hostnameAlias } = vmInfo

    vmPrefix = (@parseAlias hostnameAlias)?.prefix or hostnameAlias

    modal = new VmDangerModalView
      name     : vmInfo.hostnameAlias
      title    : "Destroy '#{hostnameAlias}'"
      action   : "Destroy my VM"
      callback : =>
        @deleteVmByHostname hostnameAlias, (err) ->
          return if KD.showError err
          new KDNotificationView title:'Successfully destroyed!'
        modal.destroy()
    , vmPrefix

  deleteVmByHostname: (hostnameAlias, callback) ->
    { JVM } = KD.remote.api

    JVM.removeByHostname hostnameAlias, (err)->
      return callback err  if err

      vmc = KD.getSingleton("vmController")
      vmc.emit 'VMListChanged'
      vmc.emit 'VMDestroyed', hostnameAlias

      callback null

  remove: (vm, callback=noop)->
    @fetchVmInfo vm, (err, vmInfo)=>
      return  if KD.showError err

      if vmInfo

        if vmInfo.underMaintenance is yes
          message = "Your VM is under maintenance, not allowed to delete."
          new KDNotificationView title: message
          callback { message }

        else
          @confirmVmDeletion vmInfo

      else
        new KDNotificationView title: 'Failed to remove!'
        callback { message: "No such VM!" }

  info:(vm, callback)->
    [callback, vm] = [vm, callback]  if 'function' is typeof vm
    @_runWrapper 'vm.info', vm, (err, info)=>
      warn "[VM-#{vm}]", err  if err
      if err?.name is "UnderMaintenanceError"
        info = state: "MAINTENANCE"
        err  = null
        delete @vmRegions[vm]
      @emit 'StateChanged', err, vm, info
      callback? err, vm, info

  fetchRegion: (vmName, callback)->
    if region = @vmRegions[vmName]
      return @utils.defer -> callback region

    KD.remote.api.JVM.fetchVmRegion vmName, (err, region)=>
      if err or not region
        warn err  if err
        callback 'sj' # This by default 'aws' please change it if needed! ~ GG
      else
        @vmRegions[vmName] = region
        callback @vmRegions[vmName]

  fetchVmName: (options, callback) ->
    if options.vmName?
      @utils.defer -> callback null, options.vmName
    else
      @fetchDefaultVmName (defaultVmName) ->
        if defaultVmName?
        then callback null, defaultVmName
        else callback message: 'There is no VM for this account.'

  fetchDefaultVmName:(callback=noop, force=no)->
    if @defaultVmName and not force
      return @utils.defer => callback @defaultVmName

    {entryPoint}   = KD.config
    currentGroup   = if entryPoint?.type is 'group' then entryPoint.slug
    currentGroup or= KD.defaultSlug

    @fetchVMs (err, vmNames)=>
      if err or not vmNames
        return callback null

      # If there is just one return it
      if vmNames.length is 1
        return callback @defaultVmName = vmNames.first

      # If current group is 'koding' ask to backend for the default one
      KD.remote.api.JVM.fetchDefaultVm (err, defaultVmName)=>
        if currentGroup is 'koding' and defaultVmName
          return callback @defaultVmName = defaultVmName

        vmSort   = (x,y)-> x.uid - y.uid
        vms      = (@parseAlias vm for vm in vmNames)
        userVMs  = (vm for vm in vms when vm?.type is 'user').sort vmSort
        groupVMs = (vm for vm in vms when vm?.type is 'group').sort vmSort

        # Check for personal VMs in current group
        for vm in userVMs when vm.groupSlug is currentGroup
          return callback @defaultVmName = vm.alias

        # Check for shared VMs in current group
        for vm in groupVMs when vm.groupSlug is currentGroup
          return callback @defaultVmName = vm.alias

        # Check for personal VMs in Koding or Guests group
        for vm in userVMs when vm.groupSlug in ['koding', 'guests']
          return callback @defaultVmName = vm.alias

        # Fallback to Koding VM if exists
        return callback @defaultVmName = defaultVmName

  createGroupVM:(type='user', planCode, callback=->)->
    vmCreateCallback = (err, vm)->
      vmController = KD.getSingleton('vmController')

      if err
        warn err
        return new KDNotificationView
          title : err.message or "Something bad happened while creating VM"
      else
        # KD.getSingleton("finderController").mountVm vm.hostnameAlias
        vmController.emit 'VMListChanged'
        vmController.showVMDetails vm

    defaultVMOptions = {planCode}
    group = KD.getSingleton("groupsController").getCurrentGroup()
    group.createVM {type, planCode}, vmCreateCallback

  fetchVMs: do (waiting = []) -> (force, callback)->
    [callback, force] = [force, callback]  unless callback?

    return  unless callback?

    if @vms.length
      @utils.defer => callback null, @vms
      return

    return  if not force and (waiting.push callback) > 1

    KD.remote.api.JVM.fetchVms (err, vms)=>
      @vms = vms  unless err
      if force
      then callback err, vms
      else
        cb err, vms  for cb in waiting
        waiting = []

  fetchGroupVMs:(force, callback = noop)->
    if @groupVms.length > 0 and not force
      return @utils.defer =>
        callback null, @groupVms

    KD.remote.api.JVM.fetchVmsByContext (err, vms)=>
      @groupVms = vms  unless err
      callback? err, vms

  fetchVMDomains:(vmName, callback = noop)->
    if domains = @vmDomains[vmName]
      return @utils.defer -> callback null, domains

    KD.remote.api.JVM.fetchDomains vmName, (err, domains=[])=>
      if err
        callback err, domains
      else
        @vmDomains[vmName] = domains.sort (x, y)-> x.length>y.length
        callback null, @vmDomains[vmName]

  resetVMData:->
    @vms      = []
    @groupVms = []
    @defaultVmName = null
    @vmDomains = {}
    @vmRegions = {}

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

  fetchDiskUsage:(vmName, callback = noop)->
    command = """df | grep aufs | awk '{print $2, $3}'"""
    @run { vmName, withArgs:command }, (err, res)->
      if err or not res then [max, current] = [0, 0]
      else [max, current] = res.trim().split " "
      warn err  if err
      callback
        max     : 1024 * parseInt max, 10
        current : 1024 * parseInt current, 10

  fetchRamUsage:(vmName, callback = noop)->
    @info vmName, (err, vm, info)->
      if err or info.state isnt "RUNNING" then [max, current] = [0, 0]
      else [max, current] = [info.totalMemoryLimit, info.memoryUsage]
      warn err  if err
      callback {max, current}

  hasDefaultVM:(callback)->
    KD.remote.api.JVM.fetchDefaultVm callback

  createDefaultVM: (callback)->
    @hasDefaultVM (err, state)->
      return warn 'Default VM already exists.'  if state

      notify = new KDNotificationView
        title         : "Creating your VM..."
        overlay       :
          transparent : no
          destroyOnClick: no
        loader        :
          color       : "#ffffff"
        duration      : 120000

      { JVM } = KD.remote.api
      JVM.createFreeVm (err, vm)->
        unless err
          vmController = KD.getSingleton('vmController')
          vmController.fetchDefaultVmName (defaultVmName)->
            vmController.emit 'VMListChanged'
            notify.destroy()
            callback?()
        else
          notify?.destroy()
          KD.showError err

  createNewVM: (callback)->
    @hasDefaultVM (err, state)=>
      create = @bound if state then "createPaidVM" else "createDefaultVM"
      create callback

  showVMDetails: (vm)->
    vmName = vm.hostnameAlias
    url    = "http://#{vm.hostnameAlias}"

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

    productForm = new VmProductForm

    payment = KD.getSingleton 'paymentController'

    group = KD.singleton("groupsController").getCurrentGroup()
    if group.slug is "koding"
      payment.fetchSubscriptionsWithPlans tags: ['vm'], (err, subscriptions) ->
        return KD.showError err  if err
        productForm.setCurrentSubscriptions subscriptions
    else
      group.fetchSubscription (err, subscription) ->
        return KD.showError err  if err
        productForm.setCurrentSubscriptions [subscription]

    productForm.on 'PackOfferingRequested', (subscription) ->
      KD.remote.api.JPaymentPack.one tags: 'vm', (err, pack) ->
        return KD.showError err  if err
        productForm.setContents 'packs', [pack]

    workflow = new PaymentWorkflow
      productForm: productForm
      confirmForm: new VmPaymentConfirmForm

    modal = new FormWorkflowModal
      title   : "Create a new VM"
      view    : workflow
      height  : "auto"
      width   : 500
      overlay : yes

    workflow
      .on 'DataCollected', (data) =>
        @provisionVm data
        modal.destroy()

      .on('Cancel', modal.bound 'destroy')

      .enter()

  provisionVm: ({ subscription, paymentMethod, productData })->
    { JVM } = KD.remote.api

    { plan, pack } = productData

    payment = KD.getSingleton 'paymentController'

    if paymentMethod and not subscription

      plan.subscribe paymentMethod.paymentMethodId, (err, subscription) =>
        return  if KD.showError err

        @provisionVm { subscription, productData }

      return

    payment.debitSubscription subscription, pack, (err, nonce) =>
      return  if KD.showError err

      JVM.createVmByNonce nonce, (err, vm) =>
        return  if KD.showError err

        @emit 'VMListChanged'
        @showVMDetails vm

  askForApprove:(command, callback)->

    switch command
      when 'vm.stop', 'vm.shutdown'
        content = """<p>Turning off your VM will <b>stop</b> running Terminal
                     instances and all running processes that you have on
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

  askToTurnOn:(options, callback)->

    [options, callback] = [callback, options]  if typeof options is "function"
    {appName, vmName, state} = options

    title   = "Your VM is turned off"
    content = """To #{if appName then 'run' else 'do this'} <b>#{appName}</b>
                 you need to turn on your VM first, you can do that by
                 clicking '<b>Turn ON VM</b>' button below."""

    unless @defaultVmName
      title   = "You don't have any VM"
      content = """To #{if appName then 'use' else 'do this'}
                 <b>#{appName or ''}</b> you need to have at lease one VM
                 created, you can do that by clicking '<b>Create Default
                 VM</b>' button below."""

    if state is "MAINTENANCE"
      title   = "Your VM is under maintenance"
      content = """Your VM <b>#{vmName}</b> is <b>UNDER MAINTENANCE</b> now,
                   #{if appName then "to run <b>#{appName}</b> app"} please try
                   again later."""

    _runAppAfterStateChanged = (appName, vmName)=>
      return  unless appName
      params = params: {vmName}  if vmName
      @once 'StateChanged', (err, vm, info)->
        return  if err or not info or info.state isnt "RUNNING"
        return  unless vm is vmName
        KD.utils.wait 1200, ->
          KD.getSingleton("appManager").open appName, params

    modal = new KDModalView
      title          : title
      content        : "<div class='modalformline'><p>#{content}</p></div>"
      height         : "auto"
      overlay        : yes
      buttons        :
        'Turn ON VM' :
          style      : "modal-clean-green"
          callback   : =>
            _runAppAfterStateChanged appName, vmName
            @start vmName, ->
              modal.destroy()
              callback?()
        'Create Default VM' :
          style      : "modal-clean-green"
          callback   : =>
            _runAppAfterStateChanged appName
            @createNewVM callback
            modal.destroy()
        Cancel       :
          style      : "modal-cancel"
          callback   : ->
            modal.destroy()
            callback? cancel: yes

    if @defaultVmName then modal.buttons['Create Default VM'].destroy() \
                      else modal.buttons['Turn ON VM'].destroy()

    if state is "MAINTENANCE"
      modal.setButtons
        Ok           :
          style      : "modal-clean-gray"
          callback   : ->
            modal.destroy()
            callback? cancel: yes
      , yes

    modal.once 'KDModalViewDestroyed', -> callback? destroy: yes

  # there may be a better place for these who methods below - SY

  fetchVMPlans: (callback) ->

    { JPaymentPlan } = KD.remote.api

    @emit "VMPlansFetchStart"

    JPaymentPlan.fetchPlans tag: 'vm', (err, plans) =>
      return warn err  if err

      if plans then plans.sort (a, b) -> a.feeAmount - b.feeAmount

      @emit "VMPlansFetchEnd"

      callback err, plans

  sanitizeVMPlansForInputs:(plans)->
    # fix this one on radios value cannot have some chars and that's why i keep index as the value
    descriptions = plans.map (plan) -> plan.description
    hostTypes    = plans.map (plan, i)->
      title      : plan.description.title
      value      : i
      feeAmount  : (plan.feeAmount / 100).toFixed 0

    { descriptions, hostTypes }

  # This is a copy of JVM.parseAlias
  # make sure to update this if change other one ~ GG
  parseAlias:(alias)->
    # group-vm alias
    if /^shared\-[0-9]+/.test alias
      result = alias.match /(.*)\.([a-z0-9\-]+)\.kd\.io$/
      if result
        [rest..., prefix, groupSlug] = result
        uid = parseInt(prefix.split(/-/)[1], 10)
        return {groupSlug, prefix, uid, type:'group', alias}
    # personal-vm alias
    else if /^vm\-[0-9]+/.test alias
      result = alias.match /(.*)\.([a-z0-9\-]+)\.([a-z0-9\-]+)\.kd\.io$/
      if result
        [rest..., prefix, nickname, groupSlug] = result
        uid = parseInt(prefix.split(/-/)[1], 10)
        return {groupSlug, prefix, nickname, uid, type:'user', alias}
    return null
