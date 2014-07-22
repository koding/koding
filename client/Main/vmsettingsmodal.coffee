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
              label         : 'Your VM is pointed to'
            #   name          : 'domain'
            #   type          : 'select'
            #   itemClass     : KDSelectBox
            #   defaultValue  : ''
            #   selectOptions : @bound 'prepareDomainOptions'
            # addDomain       :
            #   label         : ''
              name          : 'addDomain'
              placeholder   : 'type a domain name'
              nextElement   :
                extras      :
                  itemClass : KDCustomHTMLView
                  cssClass  : 'root-domain'
                  partial   : ".#{KD.whoami().profile.nickname}.kd.io"
                domainButton:
                  itemClass : KDButtonView
                  title     : 'Add domain'
                  callback  : => log 'add ulan'
                cancelButton:
                  itemClass : KDButtonView
                  title     : 'Cancel'
                  callback  : @bound 'hideAddDomain'
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

    {advanced, domain, addDomain} = @modalTabs.forms.Settings.inputs
    {hostnameAlias} = @getData()
    {label} = advanced.getOptions()

    advanced.hide()
    label.setClass 'advanced'

    advanced.addSubView new KDButtonView
      style    : 'solid compact green'
      title    : 'Re-initialize VM'
      callback : -> KD.singletons.vmController.reinitialize hostnameAlias, ->

    advanced.addSubView deleteButton = new KDButtonView
      style    : 'solid compact red'
      title    : 'Delete VM'
      callback : =>

        unless deleteButton.beingConfirmed
          deleteButton.setTitle 'Are you sure?'
          deleteButton.beingConfirmed = yes
          return

        KD.singletons.vmController.deleteVmByHostname hostnameAlias, (err) =>

          return KD.showError err  if err

          {dock} = KD.singletons
          dock.fetchVMs (vms) ->
            dock.vmsList.removeAllItems()
            dock.listVMs vms

          @destroy()


    label.on 'click', (event) =>
      KD.utils.stopDOMEvent event
      label.toggleClass 'expanded'
      advanced.toggleClass 'hidden'

    @modalTabs.forms.Settings.fields.addDomain.hide()
    domain.on 'change', =>
      if domain.getValue() is 'add-domain'
      then @showAddDomain()
      else
        @hideAddDomain()
        @linkDomain domain.getValue()

    addDomain.on 'keyup', (event) =>
      @hideAddDomain()  if event.which is 27

    # FIXME - SY
    # domain.setValue to the domain which vm is connected to
    # alwaysOn.setValue if the vm is always on


  hideAddDomain: ->

    @modalTabs.forms.Settings.fields.domain.show()
    @modalTabs.forms.Settings.fields.addDomain.hide()

  showAddDomain: ->

    @modalTabs.forms.Settings.fields.domain.hide()
    @modalTabs.forms.Settings.fields.addDomain.show()
    @modalTabs.forms.Settings.inputs.addDomain.setFocus()



  linkDomain: (domainId) ->

    return  if @asking

    @asking = yes
    {hostnameAlias} = @getData()

    [jDomain] = @currentDomains.filter (domain) -> domain._id is domainId

    jDomain.bindVM {hostnameAlias}, (err) =>

      @asking = no
      return  if KD.showError err


  prepareDomainOptions: (callback) ->

    KD.remote.api.JDomain.fetchDomains (err, domains) =>

      @currentDomains = domains

      if err
        @modalTabs.forms.Settings.fields.domain.hide()
        return callback [ title : "Couldn't retrieve domains!" ]


      options = domains.map (jdomain) -> title : jdomain.domain, value : jdomain._id
      options.unshift title : 'No domain', value : 'no-domain'
      options.push    title : '+ Add another domain...', value : 'add-domain'

      callback options
