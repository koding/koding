class VMSettingsModal extends KDModalViewWithForms

  constructor: (options = {}, data) ->

    options.title    or= 'Configure Your VM'
    options.cssClass or= 'activity-modal vm-settings'
    options.content  or= ''
    options.overlay   ?= yes
    options.width     ?= 400
    options.height   or= 'auto'
    options.arrowTop or= no
    options.tabs     or=
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
                  partial   : ".#{KD.whoami().profile.nickname}.kd.io"
                Save        :
                  itemClass : KDButtonView
                  title     : 'Save'
                  cssClass  : 'solid compact green hidden fl'
                  callback  : @bound 'linkDomain'
                toggleLink  :
                  itemClass : KDToggleButton
                  cssClass  : 'solid compact clear fr subdomain-toggler'
                  loader    : yes
                  states    : [
                    { title : 'point to a subdomain',    callback : @bound 'convertToSubdomainField' }
                    { title : 'point to my root domain', callback : @bound 'revertToDomainField' }
                  ]
            alwaysOn        :
              label         : 'Keep your VM always on'
              name          : 'alwaysOn'
              itemClass     : KodingSwitch
              defaultValue  : off
            advanced        :
              label         : 'Advanced settings'
              itemClass     : KDCustomHTMLView


    super options, data

    @addSubView new KDCustomHTMLView
      cssClass : 'modal-arrow'
      position :
        top    : 20

    {hostnameAlias}    = @getData()
    {advanced, domain} = @modalTabs.forms.Settings.inputs
    {label}            = advanced.getOptions()

    advanced.hide()
    label.setClass 'advanced'

    advanced.addSubView new KDButtonView
      style    : 'solid compact green'
      title    : 'Re-initialize VM'
      callback : -> KD.singletons.vmController.reinitialize hostnameAlias, ->

    advanced.addSubView @deleteButton = new KDButtonView
      style    : 'solid compact red'
      title    : 'Delete VM'
      callback : @bound 'deleteVM'

    label.on 'click', @bound 'toggleAdvancedSettings'

    @fetchDomains (jDomain) ->
      domain.setValue jDomain.domain  if jDomain





    # FIXME - SY
    # domain.setValue to the domain which vm is connected to
    # alwaysOn.setValue if the vm is always on

  handleChange: ->

    {domain, Save} = @modalTabs.forms.Settings.inputs
    inputValue     = domain.getValue()

    if inputValue isnt @currentDomain?.domain and inputValue isnt ''
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
    toggle()


  revertToDomainField: (toggle) ->

    {nickname} = KD.whoami().profile
    {rootDomain, domain} = @modalTabs.forms.Settings.inputs
    rootDomain.hide()
    domain.setValue "#{nickname}.kd.io"

    @handleChange()
    toggle()


  toggleAdvancedSettings: (event) ->

    KD.utils.stopDOMEvent event

    {advanced} = @modalTabs.forms.Settings.inputs
    {label} = advanced.getOptions()

    label.toggleClass 'expanded'
    advanced.toggleClass 'hidden'


  deleteVM: ->

    {hostnameAlias} = @getData()

    KD.singletons.vmController.confirmVmDeletion @getData(), (err) =>

      return KD.showError err  if err

      @refreshSidebarVMs()
      @destroy()


  linkDomain: ->

    {hostnameAlias} = @getData()

    {domain} = @modalTabs.forms.Settings.inputs

    log "@gokmen please add this domain #{domain.getValue()}"


  fetchDomains: (callback = ->) ->

    {hostnameAlias} = @getData()

    KD.remote.api.JDomain.fetchDomains (err, domains) =>

      if err
        @modalTabs.forms.Settings.fields.domain.hide()
        return callback [ title : "Couldn't retrieve domains!" ]

      [domain] = domains.filter (domain) -> domain.hostnameAlias.first is hostnameAlias
      @currentDomain = domain
      callback domain


  refreshSidebarVMs: ->

    {dock} = KD.singletons
    dock.fetchVMs (vms) ->
      dock.vmsList.removeAllItems()
      dock.listVMs vms

