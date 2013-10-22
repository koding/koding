class VirtualizationController extends KDController

  constructor:->
    super

    @kc = KD.getSingleton("kiteController")
    @dialogIsOpen = no
    @resetVMData()

    (KD.getSingleton 'mainController').once 'AppIsReady', => @fetchVMs()
    @on 'VMListChanged', @bound 'resetVMData'

  run:(options, callback = noop)->
    [callback, options] = [options, callback]  unless callback
    options ?= {}
    if "string" is typeof options
      command = options
      options =
        withArgs : command

    @fetchVmName options, (err, vmName) =>

      # if /^vm\./.test options.method
      #   options.kiteName = "osk"

      if vmName is "local-#{KD.whoami().profile.nickname}"
        if /^fs\./.test options.method
            options.kiteName = "fs"

        if /^webterm\./.test options.method
            options.kiteName = "terminal"

        if /^vm\./.test options.method
          options.kiteName = "fs"

      if options.method in ['exec', 'spawn']
        options.kiteName = "os-local"

      options.correlationName = vmName
      @fetchRegion vmName, (region)=>
        # NEWKITE
        options.kiteName or= "os-#{region}"
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

  remove: do->

    deleteVM = (vm, cb)->
      KD.remote.api.JVM.removeByHostname vm, (err)->
        return cb err  if err
        KD.getSingleton("finderController").unmountVm vm
        KD.getSingleton("vmController").emit 'VMListChanged'
        cb null

    (vm, callback=noop)->
      KD.remote.api.JVM.fetchVmInfo vm, (err, vmInfo)=>
        if vmInfo

          if vmInfo.underMaintenance is yes
            message = "Your VM is under maintenance, not allowed to delete."
            new KDNotificationView title : message
            callback {message}

          else if vmInfo.planCode is 'free'
            {hostnameAlias} = vmInfo
            vmPrefix = (@parseAlias hostnameAlias)?.prefix or hostnameAlias

            modal = new VmDangerModalView
              name     : vmInfo.hostnameAlias
              title    : "Destroy '#{hostnameAlias}'"
              action   : "Destroy my VM"
              callback : =>
                deleteVM vm, callback
                new KDNotificationView title:'Successfully destroyed!'
                modal.destroy()
            , vmPrefix
          else
            paymentController = KD.getSingleton('paymentController')
            paymentController.deleteVM vmInfo, (state)->
              return callback null  unless state
              deleteVM vm, callback
        else
          new KDNotificationView
            title: 'Failed to remove!'
          callback message: "No such VM!"

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
    unless vmName
      return @utils.defer -> callback "local"
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
        KD.getSingleton("finderController").mountVm vm.hostnameAlias
        vmController.emit 'VMListChanged'
        vmController.showVMDetails vm

    defaultVMOptions = {planCode}
    group = KD.getSingleton("groupsController").getCurrentGroup()
    group.createVM {type, planCode}, vmCreateCallback

  fetchVMs: do (waiting = []) ->
    (force, callback)->
      [callback, force] = [force, callback]  unless callback?
      return  unless callback?

      if @vms.length
        return @utils.defer => callback null, @vms

      if not force and (waiting.push callback) > 1
        return  callback null, []

      KD.remote.api.JVM.fetchVms (err, vms)=>
        @vms = vms  unless err
        if force
        then callback err, vms
        else
          cb err, vms  for cb in waiting
          waiting = []


  fetchGroupVMs:(callback = noop)->
    if @groupVms.length > 0
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

      KD.remote.cacheable KD.defaultSlug, (err, group)->
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
              notify.destroy()
              callback?()
          else
            notify?.destroy()
            KD.showError err

  createNewVM: (callback)->
    @hasDefaultVM (err, state)=>
      if state then @createPaidVM() else @createDefaultVM callback

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
                  KD.track "User Clicked Buy VM", KD.nick()
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

  askToTurnOn:(options, callback)->

    [options, callback] = [callback, options]  if typeof options is "function"
    {appName, vmName, state} = options

    return  if @dialogIsOpen

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

    @dialogIsOpen = yes
    modal.once 'KDModalViewDestroyed', => @dialogIsOpen = no

  # there may be a better place for these who methods below - SY

  fetchVMPlans:(callback)->
    @emit "VMPlansFetchStart"
    KD.remote.api.JRecurlyPlan.getPlans "group", "vm", (err, plans)=>
      if err then warn err
      else if plans
        plans.sort (a, b)-> a.feeMonthly - b.feeMonthly

      @emit "VMPlansFetchEnd"
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
