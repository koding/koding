class MachineSettingsModal extends KDModalViewWithForms

  { Running, Starting } = Machine.State

  stateClasses = ""
  for state in Object.keys Machine.State
    stateClasses += "#{state.toLowerCase()} "

  constructor: (options = {}, data) ->

    domainSuffix = ".#{KD.nick()}.#{KD.config.userSitesDomain}"
    running      = data.status.state in [ Running, Starting ]

    options.title         or= 'Configure Your VM'
    options.cssClass      or= 'activity-modal vm-settings'
    options.content       or= ''
    options.overlay        ?= yes
    options.width          ?= 400
    options.height        or= 'auto'
    options.arrowTop      or= no
    options.tabs          or=
      forms                 :
        Settings            :
          fields            :
            domain          :
              label         : 'Point to'
              name          : 'addDomain'
              placeholder   : 'type a domain name'
              keyup         : @bound 'handleChange'
              change        : @bound 'handleChange'
              nextElement   :
                rootDomain  :
                  itemClass : KDCustomHTMLView
                  cssClass  : 'root-domain hidden'
                  partial   : domainSuffix
                Save        :
                  itemClass : KDButtonView
                  title     : 'Save'
                  cssClass  : 'solid compact green hidden fl'
                  callback  : @bound 'linkDomain'
                # toggleLink  :
                #   itemClass : KDToggleButton
                #   cssClass  : 'solid compact clear fr subdomain-toggler'
                #   loader    : yes
                #   states    : [
                #     { title : 'point to a subdomain',    callback : @bound 'convertToSubdomainField' }
                #     { title : 'point to my root domain', callback : @bound 'revertToDomainField' }
                #   ]
            # alwaysOn        :
            #   label         : 'Keep your VM always on'
            #   name          : 'alwaysOn'
            #   itemClass     : KodingSwitch
            #   defaultValue  : off
            provider        :
              label         : "Provider"
              itemClass     : CustomLinkView
              title         : KD.config.providers[data.provider].name
              href          : KD.config.providers[data.provider].link
            publicIp        :
              label         : "Public IP"
              cssClass      : if running then "" else "hidden"
              itemClass     : CustomLinkView
              title         : data.ipAddress or "N/A"
              href          : if data.ipAddress? then "http://#{data.ipAddress}"
            currentStatus   :
              label         : "Current status"
              itemClass     : KDView
              cssClass      : "custom-link-view"
              partial       : data.status.state
              # click         : -> # FIXME GG (Add troubleshoot modal? )
            statusToggle    :
              label         : "Change machine state"
              defaultValue  : running
              itemClass     : KodingSwitch
              callback      : (state)->
                if state
                then computeController.start data
                else computeController.stop data

            advanced        :
              label         : 'Advanced settings'
              itemClass     : KDCustomHTMLView


    super options, data

    @machine = machine = @getData()
    { computeController } = KD.singletons
    { Terminated, NotInitialized, Building, Terminating } = Machine.State

    @addSubView @over = new KDView
      cssClass : "modal-inline-overlay"

    @over.addSubView new KDCustomHTMLView
      tagName  : "p"
      partial  : """This machine created but not initialized,
        to be able to use it you need to initialize it first.
        Do you want to do it now?"""

    @over.addSubView new KDButtonView
      title    : "Initialize"
      cssClass : "solid green medium"
      loader   :
        color  : '#fff'
        show   : machine.status.state in [Building, Terminating]
      callback : ->
        @showLoader()
        KD.singletons.computeController.build machine

    computeController.on "public-#{machine._id}", @bound 'updateState'

    @over.hide()  if machine.status.state not in [
      Terminated, NotInitialized, Building, Terminating
    ]


    @addSubView new KDCustomHTMLView
      cssClass : 'modal-arrow'
      position :
        top    : 20

    {advanced} = @modalTabs.forms.Settings.inputs
    {label}    = advanced.getOptions()

    advanced.hide()
    label.setClass 'advanced'

    advanced.addSubView new KDButtonView
      style    : 'solid compact red'
      title    : 'Terminate VM'
      callback : => KD.singletons.computeController.destroy @machine

    advanced.addSubView @deleteButton = new KDButtonView
      style    : 'solid compact red'
      title    : 'Delete VM'
      callback : @bound 'deleteVM'

    label.on 'click', @bound 'toggleAdvancedSettings'

    # If JMachine data loaded from KD.userMachines
    # we need to revive them once from DB to be able to use
    # provided instance methods on it.
    unless @machine.jMachine["ಠ_ಠ"]
      KD.remote.api.JMachine.one @machine.uid, (err, jMachine)=>
        info "Revived from DB", err, jMachine
        unless err then @machine.jMachine = jMachine
        @_setDomainField()
    else
      @_setDomainField()

  updateState:(event)->

    {status, reverted} = event

    return unless status

    {Running, Starting, NotInitialized, Terminated} = Machine.State

    if reverted
      warn "State reverted!"

    @unsetClass stateClasses
    @setClass status.toLowerCase()

    { currentStatus, statusToggle } = @modalTabs.forms.Settings.inputs

    if status in [ Running, Starting ]
    then statusToggle.setOn no
    else statusToggle.setOff no

    currentStatus.updatePartial status

    @machine.jMachine.setAt "status.state", status
    @machine.updateLocalData()


  _setDomainField: ->

    domainSuffix = ".#{KD.nick()}.#{KD.config.userSitesDomain}"

    {domain} = @modalTabs.forms.Settings.inputs
    _domain  = @machine.jMachine.domain
    if ///#{domainSuffix}$///.test _domain
      _domain = _domain.replace ///#{domainSuffix}$///, ""

    @convertToSubdomainField()
    domain.setValue _domain


  handleChange: ->

    {domain, Save} = @modalTabs.forms.Settings.inputs
    inputValue     = domain.getValue()

    if inputValue isnt @machine.domain and inputValue isnt ''
    then Save.show()
    else Save.hide()


  submitDomainChange: ->

    {domain} = @modalTabs.forms.Settings.inputs
    if domain.getValue() is 'add-domain'
    then @convertToSubdomainField()
    else @revertToDomainField()


  convertToSubdomainField: (toggle) ->

    {rootDomain, domain} = @modalTabs.forms.Settings.inputs
    rootDomain.show()

    domain.setValue ''

    @handleChange()
    domain.setFocus()
    toggle?()


  revertToDomainField: (toggle) ->

    {nickname} = KD.whoami().profile
    {rootDomain, domain} = @modalTabs.forms.Settings.inputs
    rootDomain.hide()
    domain.setValue "#{nickname}.kd.io"

    @handleChange()
    toggle?()


  toggleAdvancedSettings: (event) ->

    KD.utils.stopDOMEvent event

    {advanced} = @modalTabs.forms.Settings.inputs
    {label} = advanced.getOptions()

    label.toggleClass 'expanded'
    advanced.toggleClass 'hidden'


  deleteVM: ->

    {computeController} = KD.singletons
    computeController.destroy @machine


  linkDomain: ->

    domainSuffix = ".#{KD.nick()}.#{KD.config.userSitesDomain}"
    domain = @modalTabs.forms.Settings.inputs.domain.getValue() + domainSuffix

    @machine.jMachine.setDomain domain, (err)=>
      unless err
        @machine.jMachine.domain = domain
        @machine.updateLocalData()
      new KDNotificationView title : err?.message or "Domain settings updated"

