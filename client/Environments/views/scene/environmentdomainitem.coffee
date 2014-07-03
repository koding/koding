class EnvironmentDomainItem extends EnvironmentItem

  constructor:(options={}, data)->

    options.cssClass           = 'domain'
    options.joints             = ['right']

    options.allowedConnections =
      EnvironmentMachineItem   : ['left']

    super options, data

    {@domain} = @getData()


  updateStateStyle:->
    if @domain.domain?
    then @setClass 'verified'
    else @unsetClass 'verified'


  confirmDestroy:->

    @deletionModal = new DomainDeletionModal {}, @domain
    @deletionModal.on "domainRemoved", @bound 'destroy'

  getState:->

    states = ["Activate", "Deactivate"]

    if @domain.domain
      title        : states[1]
      newTitle     : states[0]
      newData      : null
      notification : "Deactivating..."
      command      : "deactivateDomain"
    else
      title        : states[0]
      newTitle     : states[1]
      newData      : @domain.proposedDomain
      notification : "Activating..."
      command      : "activateDomain"

  toggleDomainState:->

    state = @getState()

    new KDNotificationView
      title : state.notification
      type  : "tray"

    @domain[state.command] (err)=>
      unless err
        @activateButton.setTitle state.newTitle
        @domain.domain = state.newData
        @updateStateStyle()


  viewAppended:->

    state = @getState()
    @updateStateStyle()

    @activateButton = new KDButtonView
      title    : state.title
      cssClass : "solid green mini"
      callback : @bound 'toggleDomainState'

    super

  pistachio:->
    """
      <div class='details'>
        <span class='toggle'></span>
        {h3{#(title)}}
        {{> @chevron}}
        {{> @activateButton}}
      </div>
    """
