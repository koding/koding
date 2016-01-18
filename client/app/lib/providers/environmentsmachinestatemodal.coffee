kd                      = require 'kd'
Encoder                 = require 'htmlencode'

KDButtonView            = kd.ButtonView
KDLoaderView            = kd.LoaderView
KDCustomHTMLView        = kd.CustomHTMLView
KDProgressBarView       = kd.ProgressBarView
KDNotificationView      = kd.NotificationView
KDHitEnterInputView     = kd.HitEnterInputView
KDCustomScrollView      = kd.CustomScrollView

remote                  = require('../remote').getInstance()
Machine                 = require './machine'
ComputeHelpers          = require './computehelpers'
ComputeController       = require './computecontroller'

BaseModalView           = require './views/basemodalview'
HelpSupportModal        = require '../commonviews/helpsupportmodal'

MarketingSnippetType    = require 'app/marketing/marketingsnippettype'
MarketingSnippetView    = require 'app/marketing/marketingsnippetview'

whoami                  = require 'app/util/whoami'
isKoding                = require 'app/util/isKoding'
showError               = require 'app/util/showError'
applyMarkdown           = require 'app/util/applyMarkdown'
isTeamReactSide         = require 'app/util/isTeamReactSide'
sendDataDogEvent        = require 'app/util/sendDataDogEvent'
trackInitialTurnOn      = require 'app/util/trackInitialTurnOn'
environmentDataProvider = require 'app/userenvironmentdataprovider'


module.exports = class EnvironmentsMachineStateModal extends BaseModalView

  {
    Stopped, Running, NotInitialized, Terminated, Unknown, Pending,
    Starting, Building, Stopping, Rebooting, Terminating, Updating
  } = Machine.State

  EVENT_TIMEOUT = 2 * 60 * 1000 # 2 minutes.

  constructor: (options = {}, data) ->

    options.cssClass or= 'env-machine-state'
    options.width      = 440

    super options, data

    @addSubView @readmeView = new KDCustomScrollView
      cssClass: 'content-readme hidden'
    @addSubView @container  = new KDCustomHTMLView
      cssClass: 'content-container'

    @machine = @getData()

    return @handleNoMachineFound()  unless @machine

    { computeController } = kd.singletons

    { jMachine } = @machine
    { @state }   = @machine.status

    @machineId   = jMachine._id
    @isManaged   = jMachine.provider is 'managed'
    @templateId  = jMachine.generatedFrom?.templateId ? null
    @machineName = jMachine.label

    @showBusy()
    @show()

    computeController.fetchUserPlan (plan) =>
      @userSubscription = plan

    computeController.ready => whoami().isEmailVerified (err, verified) =>

      kd.warn err  if err?

      return @buildVerifyView()  unless verified

      @stack = computeController.findStackFromMachineId @machineId
      @setReadmeContent()

      if @stack # Stack build events
        computeController.on "apply-#{@stack._id}", @bound 'updateStatus'

        # Follow on-going stack build process
        if @stack.status?.state is 'Building'
          computeController.eventListener.addListener 'apply', @stack._id

      kd.singletons.paymentController.subscriptions (err, subscription) =>
        kd.warn err  if err?
        if subscription?.state is 'expired'
        then @buildExpiredView subscription
        else @buildInitial()

    { marketingController } = kd.singletons
    marketingController.on 'SnippetNeedsToBeShown', @bound 'showMarketingSnippet'

    @on 'MachineTurnOnStarted', (machine) ->
      sendDataDogEvent 'MachineTurnedOn', tags: {label: machine.label}
      trackInitialTurnOn machine


  triggerEventTimer: (percentage) ->

    if percentage isnt @_lastPercentage
      clearTimeout @eventTimer
    else unless @eventTimer
      @eventTimer = kd.utils.wait EVENT_TIMEOUT, @bound 'createRetry'

    @_lastPercentage = percentage


  clearEventTimer: ->

    @retryView?.destroy()
    @eventTimer = clearTimeout @eventTimer


  updateStatus: (event, task) ->

    return  if @_busy

    { status, percentage, error, message } = event

    if status is @state
      @updatePercentage percentage  if percentage?

    else

      [ @oldState, @state ] = [ @state, status ]

      if error

        if /NetworkOut/i.test error

          limitReachedNotice = "
            <p>You've reached your outbound network
            usage limit for this week.</p>
          "

          if @userSubscription is 'free'
            @customErrorMessage = "
              #{limitReachedNotice}<span>
              Please upgrade your <a href='/Pricing'>plan</a> or
              <span class='contact-support'>contact support</span> for further
              assistance.</span>
            "

          else
            @customErrorMessage = "
              #{limitReachedNotice}<span>
              Please <span class='contact-support'>contact support</span>
              for further assistance.</span>
            "

        unless error.code is ComputeController.Error.NotVerified
          @lastKnownError = error

      if not percentage?
        @switchToIDEIfNeeded()

      else if percentage is 100
        initial = message in [ 'apply finished', 'reinit finished' ]
        @completeCurrentProcess status, initial

      else if task is 'reinit'
        @updatePercentage percentage
        @updateReinitState()

      else
        @clearEventTimer()
        @buildViews()

    @createStatusOutput event


  switchToIDEIfNeeded: (status = @state, initial = no) ->

    return no  unless status is Running
    @prepareIDE initial
    @destroy()
    return yes


  updatePercentage: (percentage) ->

    @triggerEventTimer percentage

    @progressBar?.updateBar Math.max percentage, 10
    @progressBar?.show()


  updateReinitState: ->

    @label?.updatePartial @getStateLabel()


  completeCurrentProcess: (status, initial) ->


    @clearEventTimer()

    @progressBar?.updateBar 100
    @progressBar?.show()

    if @oldState is Building and @state is Running
      cc = kd.getSingleton 'computeController'
      cc.once "revive-#{@machineId}", =>
        @switchToIDEIfNeeded status, initial
    else
      unless @switchToIDEIfNeeded status, initial
        kd.utils.wait 500, => @buildViews()


  showBusy: (message) ->

    @_busy = message?

    @container.destroySubViews()

    @createStateLabel message ? "Loading..."
    @createLoading()


  buildInitial: ->

    return @buildViews()  if @_initialBuiltOnce

    computeController = kd.getSingleton 'computeController'

    computeController.on "start-#{@machineId}", @bound 'updateStatus'
    computeController.on "build-#{@machineId}", @bound 'updateStatus'
    computeController.on "stop-#{@machineId}",  @bound 'updateStatus'

    computeController.on "reinit-#{@machineId}", (event) =>
      @updateStatus event, 'reinit'

    computeController.on "resize-#{@machineId}", (event) =>
      @updateStatus event, 'resize'

    if @isManaged
      computeController.on "public-#{@machineId}", @bound 'updateStatus'

    computeController.eventListener.followUpcomingEvents @machine

    @eventTimer = null
    @_lastPercentage = 0
    @_initialBuiltOnce = yes

    @container.destroySubViews()

    @createStateLabel "Checking state for <strong>#{@machineName or ''}</strong>..."

    @createLoading()
    @createFooter()

    if @getOption 'initial'

      currentState = @machine.status.state

      if currentState is NotInitialized
        @buildViews State: currentState
        return

      @triggerEventTimer 10

      kd.getSingleton 'computeController'
        .getKloud().info { @machineId, currentState }
        .then (response) =>

          kd.info "Initial info result:", response

          @buildViews response

        .catch (err) =>

          unless err?.code is ComputeController.Error.NotVerified
            kd.warn "Failed to fetch initial info:", err
            @lastKnownError = err

          @buildViews()

    else
      @buildViews()


  buildVerifyView: ->

    @container.destroySubViews()

    @codeEntryView = new KDHitEnterInputView
      type         : 'text'
      cssClass     : 'verify-pin-input'
      placeholder  : 'Enter code here'
      callback     : @bound 'verifyAccount'

    @button    = new KDButtonView
      title    : 'Verify account'
      cssClass : 'solid green medium'
      callback : @bound 'verifyAccount'

    @container.addSubView new KDCustomHTMLView
      cssClass : 'verify-message'
      partial  : "
        <p>Before you can access your VM, we need to verify your account.
        A verification email should already be in your inbox.
        If you did not receive it yet, you can request a
        <cite>new code</cite>.</p>
      "

      click    : (event) =>

        return  unless event.target.tagName is 'CITE'

        remote.api.JUser.verifyByPin resendIfExists: yes, (err) =>

          unless showError err

            @container.addSubView @retryView = new KDCustomHTMLView
              cssClass : 'error-message warning'
              partial  : """
                <p>Email sent, please check your inbox.</p>
              """

            kd.utils.wait 3000, @retryView.bound 'destroy'

    @container.addSubView @codeEntryView
    @container.addSubView @button


  buildExpiredView: (subscription, nextState) ->

    plan = if subscription? then "(<b>#{subscription.planTitle}</b>)" else ""

    @container.destroySubViews()

    if nextState is "downgrade"

      @showBusy "Downgrading..."
      @downgradePlan (err) =>

        if err?
          kd.utils.wait 10000, =>
            @buildExpiredView subscription, "downgrade"
        else
          ComputeHelpers.handleNewMachineRequest provider: 'koding', (err) ->
            global.location.reload yes

      return

    destroyVMs = nextState is "destroy-vms"

    @upgradeButton = new KDButtonView
      title    : 'Make Payment'
      cssClass : 'solid green medium plan-change-button'
      callback : -> kd.singletons.router.handleRoute '/Pricing'

    actionTitle = if destroyVMs then 'Delete All VMs' else 'Downgrade to Free'

    @actionButton = new KDButtonView
      title    : actionTitle
      cssClass : 'solid green medium plan-change-button downgrade'
      callback : =>

        if destroyVMs

          @showBusy "Deleting your VM(s)..."
          ComputeHelpers.destroyExistingResources yes, (err) =>
            @buildExpiredView subscription, "downgrade"

        else

          @showBusy "Downgrading..."
          @downgradePlan (err) =>
            if err?
              @buildExpiredView subscription, "destroy-vms"
            else
              @_busy = no
              @buildInitial()

    @container.addSubView new KDCustomHTMLView
      cssClass : 'expired-message'
      partial  : if destroyVMs then "
        <h1>Delete all existing VMs</h1>
        <p>To be able to downgrade your current plan #{plan} to the
        <b>Free</b> plan, you need to delete all your existing VMs. This
        action will <b>destroy all your VMs, (including YOUR FILES) and
        cannot be UNDONE!</b> Are you sure you want to continue?</p>
      " else "
        <h1>Your Koding Paid Plan Has Expired</h1>
        <p>This happens when we cannot collect a payment. As a result,
        access to your VM is restricted.</p>
        <p>To continue, you can either make a payment to lift the
        restriction or downgrade to a free account. Downgrading will delete
        your existing VM(s) (and all the data inside them)
        and give you a new default VM.</p>
      "

    unless destroyVMs
      @container.addSubView @upgradeButton

    @container.addSubView @actionButton


  buildViews: (response) ->

    return  if @_busy

    if response?.State?
      @state = response.State

    @container.destroySubViews()
    @container.unsetClass 'marketing-message'
    @progressBar = null

    if @state is 'NotFound'
      @createStateLabel 'NotFound'
    else if @isManaged and @state is Stopped
      @createStateLabel 'ManagedStopped'
    else
      @createStateLabel()

    if @state in [ Stopped, NotInitialized, Unknown, 'NotFound' ]
      @createStateButton()
    else if @state in [ Starting, Building, Pending, Stopping,
                        Terminating, Updating, Rebooting ]

      percentage = response?.percentage
      percentage = 100  if isTeamReactSide() and @state is Stopping

      @createProgressBar percentage
      @triggerEventTimer percentage
      @showRandomMarketingSnippet()  if @state is Starting
    else if @state is Terminated
      @label.destroy?()
      @createStateLabel if isKoding() then "
        The VM <strong>#{@machineName or ''}</strong> was
        successfully deleted. Please select a new VM to operate on from
        the VMs list or create a new one.
      " else "
        The VM <strong>#{@machineName or ''}</strong> was terminated.
        Please re-initalize your stack to rebuild the VM again.
      "
      @createStateButton()
    else if @state is Running
      @prepareIDE()
      @destroy()

    @createError()

    @createStatusOutput response


  statusMessagesMap  =
    'start started'  : 'Starting VM'
    'stop started'   : 'Stopping VM'
    'stop finished'  : 'VM is stopped'
    'start finished' : 'VM is ready'

  createStatusOutput: (response) ->

    message = response?.message

    if typeof message is 'string'
      message = statusMessagesMap[message] or message
      message = message.replace 'machine', 'VM'
      message = message.capitalize()

    if @logView
      @logView.updatePartial message
    else
      @addSubView @logView = new KDCustomHTMLView
        cssClass : 'stdout'
        partial  : message

    @logView[if message then 'setClass' else 'unsetClass'] 'in'



  getStateLabel: ->

    stateTexts       =
      Stopped        : if @isManaged then 'is not reachable.' else 'is turned off.'
      Starting       : 'is starting now.'
      Stopping       : 'is stopping now.'
      Pending        : 'is resizing now.'
      Running        : 'up and running.'
      Building       : 'is building now.'
      NotInitialized : 'is turned off.'
      Terminated     : 'is turned off.'
      Rebooting      : 'is rebooting.'
      Terminating    : 'is terminating.'
      Updating       : 'is updating now.'
      Unknown        : 'is turned off.'
      NotFound       : 'No machine found.' # additional class level
                                           # state to show a modal
                                           # for unknown routes.

    stackBasedStates =
      NotInitialized : 'is not build yet.'

    stackText = stateTexts[@state]

    if not isKoding() and @stack
      stackText = stackBasedStates[@state] or stateTexts[@state]

    stateText = "<strong>#{@machineName or ''}</strong> #{stackText}"
    return "<span class='icon'></span>#{stateText}"


  createStateLabel: (customState) ->

    states       =
      NotFound      : "
        <h1>You don't have any VMs!</h1>
        <span>
          This can happen if you have deleted all your VMs or if your
          VM was automatically deleted due to inactivity.
          <a href='http://learn.koding.com/faq/inactive-vms' target='_blank'>
          Learn more</a> about inactive VM cleanup.
        </span>
      "
      NoTemplate     : "
        <h1>Compute Stacks not configured yet!</h1>
        <span>
          Your team currently is not providing any compute resources.
          Please contact with your team admins for more information.
        </span>
      "
      ManagedStopped : "
        <h1><strong>Cannot connect to your machine!</strong></h1>
        <p>
          This can happen either if your machine is turned off or the
          <a href='http://learn.koding.com/guides/connect-your-machine/' target='_blank'>
          Koding Service Connector</a> is not running.</p>
        <p>
          If you want, you can also <a class='managed-disconnect'>
          disconnect</a> this machine.
        </p>
      "

    if customState is 'NotFound' and not isKoding()
      {groupsController} = kd.singletons
      customState = 'NoTemplate'  unless groupsController.currentGroupHasStack()

    @label     = new KDCustomHTMLView
      tagName  : 'p'
      partial  : states[customState] or customState or @getStateLabel()
      cssClass : "state-label #{@state.toLowerCase()}"
      click: (event) =>
        if 'managed-disconnect' in event.target.classList
          kd.utils.stopDOMEvent event
          kd.singletons.handleRoute "/Machines/#{@machine.slug}/Advanced"

    @container.addSubView @label


  createStateButton: ->

    # Don't display run button for managed vms
    return  if @isManaged

    if @state in [Terminated, 'NotFound']
      callback = 'requestNewMachine'

      if isKoding()
        title  = 'Create a new VM'
      else
        title  = 'Show Stacks'

        { groupsController } = kd.singletons
        return  unless groupsController.currentGroupHasStack()

    else if not isKoding() and @stack and @state is NotInitialized
      title    = 'Build Stack'
      callback = 'turnOnMachine'
    else
      title    = 'Turn it on'
      callback = 'turnOnMachine'

    @button    = new KDButtonView
      title    : title
      cssClass : 'turn-on state-button solid green medium'
      icon     : not @isManaged
      callback : @bound callback

    @container.addSubView @button


  createLoading: ->

    @loader?.destroy()
    @loader = new KDLoaderView
      showLoader : yes
      size       :
        width    : 40
        height   : 40

    @container.addSubView @loader


  createProgressBar: (initial = 10) ->

    @progressBar = new KDProgressBarView { initial }

    @container.addSubView @progressBar


  createRetry: ->

    @retryView?.destroy()

    return  unless @progressBar?

    @container.addSubView @retryView = new KDCustomHTMLView
      cssClass : 'error-message warning'
      partial  : """
        <p>It's taking longer than expected, please reload the page.</p>
      """


  createFooter: ->

    return  unless @state is Stopped

    computeController = kd.getSingleton 'computeController'
    computeController.fetchUserPlan (plan) =>

      reason  = @machine.status.reason
      message = null

      if /^Stopped due inactivity/.test reason
        if plan is "free"
          message = "
            Your VM was automatically turned off after 60 minutes
            of inactivity as you are on the free plan."
          upgradeMessage = """
            <a href="/Pricing" class="upgrade-link">
              Upgrade to make your VMs always-on.
            </a>
          """
        else
          message = "
            Your VM was automatically turned off after 60 minutes
            of inactivity as it is not 'Always-on' enabled."
          upgradeMessage = """
            <a href="/Pricing" class="upgrade-link">
              Upgrade to get more always-on VMs.
            </a>
          """

      upgradeMessage = ""  if plan is "professional"

      return  unless message

      @addSubView @footer = new KDCustomHTMLView
        cssClass : 'footer'
        partial  : """
          <p>#{message}</p>
          #{upgradeMessage}
        """


  createError: ->

    return  unless @lastKnownError

    sendDataDogEvent "MachineStateFailed"

    if not isKoding() and typeof @lastKnownError is 'string'
      @showErrorDetails @lastKnownError
      errorLink = ", <span class='error-details'>show details</span>"
    else
      errorLink = ''

    @errorMessage = new KDCustomHTMLView
      cssClass    : 'error-message'
      partial     : @customErrorMessage or """
        <p>There was an error when initializing your VM#{errorLink}.</p>
        <span>Please try reloading this page or <span
        class="contact-support">contact support</span> for further
        assistance.</span>
      """
      click: (event) =>
        if 'contact-support' in event.target.classList
          kd.utils.stopDOMEvent event
          new HelpSupportModal
        else if 'error-details' in event.target.classList
          kd.utils.stopDOMEvent event
          @showErrorDetails()

    @container.addSubView @errorMessage

    @lastKnownError = null


  handleNoMachineFound: ->

    {@state} = @getOptions()
    @setClass 'no-machine'
    @buildViews()
    @createFooter()
    return @show()


  findNodes: ->
    {container} = @getOptions()

    FindManagedNodesModal = require './managed/findnodesmodal'
    findNodes = new FindManagedNodesModal { container }, @machine


  requestNewMachine: ->

    kd.singletons.appManager.getFrontApp().quit()
    kd.singletons.router.handleRoute '/Stacks'


  turnOnMachine: ->

    computeController = kd.getSingleton 'computeController'
    target            = @machine

    if not isKoding() and @stack

      if @state is NotInitialized
        action = 'buildStack'
        target = @stack

      if @machine.jMachine.generatedFrom?.templateId?
        unless computeController.verifyStackRequirements @stack
          computeController.off  'StackRequirementsProvided'
          computeController.once 'StackRequirementsProvided', @bound 'turnOnMachine'
          return

    computeController.off  "error-#{target._id}"

    @emit 'MachineTurnOnStarted', @machine

    methodName   = 'start'
    nextState    = 'Starting'

    if @state in [ NotInitialized, Terminated ]
      methodName = action ? 'build'
      nextState  = 'Building'

    computeController.once "error-#{target._id}", ({err}) =>

      unless err?.code is ComputeController.Error.NotVerified
        @lastKnownError = err

      @buildViews State: @machine.status.state

    kd.singletons.computeController[methodName] target

    @state = nextState
    @buildViews()


  prepareIDE: (initial) ->


    { appManager } = kd.singletons

    environmentDataProvider.fetchMachine @machine.uid, (machine) =>

      # return showError "Couldn't fetch your VMs"  unless machine
      unless machine
        return appManager.tell 'IDE', 'quit'

      @machine = machine
      @setData machine

      @emit 'IDEBecameReady', machine, initial


  verifyAccount: ->

    code = Encoder.XSSEncode @codeEntryView.getValue()
    unless code then return new KDNotificationView
      title: "Please enter a code"

    remote.api.JUser.verifyByPin pin: code, (err) =>

      @pinIsValid?.destroy()

      if err
        @container.addSubView @pinIsValid = new KDCustomHTMLView
          cssClass : 'error-message'
          partial  : """
            <p>The pin entered is not valid.</p>
          """

      else
        kd.utils.defer @bound 'buildInitial'


  downgradePlan: (callback) ->

    me = whoami()
    me.fetchEmail (err, email) ->

      kd.singletons.paymentController
        .subscribe "token", "free", "month", { email }, (err, resp) ->
          return callback err  if err?
          callback null


  showRandomMarketingSnippet: ->

    { marketingController } = kd.singletons
    marketingController.getRandomSnippet @bound 'showMarketingSnippet'


  showMarketingSnippet: (snippet) ->

    return  unless snippet

    @marketingSnippet?.destroy()
    @marketingSnippet = new MarketingSnippetView snippet

    @container.addSubView @marketingSnippet
    @container.setClass 'marketing-message'


  setReadmeContent: ->

    # Show only for custom teams and only for NotInitalized state
    if isKoding() or not @stack or @state not in [NotInitialized, Building]
      @readmeView.hide()
      return

    { computeController } = kd.singletons
    computeController.fetchStackReadme @stack, (err, readme) =>

      if err or not readme
        @readmeView.hide()
        return

      @readmeView.wrapper.destroySubViews()

      readmeContent = new KDCustomHTMLView
        partial  : applyMarkdown readme
        cssClass : 'has-markdown'

      @readmeView.wrapper.addSubView readmeContent
      @readmeView.show()
      @readmeView.getDomElement().find('a').attr('target', '_blank')
      @setClass 'has-readme'
      @setWidth 540


  showErrorDetails: (errorMessage) ->

    kd.singletons.computeController.ui.showComputeError
      title        : "An error occured while building #{@stack.title}"
      stack        : @stack
      cssClass     : 'env-ide-error-modal'
      errorMessage : errorMessage ? @lastErrorMessage

    @lastErrorMessage = errorMessage  if errorMessage
