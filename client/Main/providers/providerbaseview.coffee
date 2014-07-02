class ProviderBaseView extends KDTabPaneView

  constructor:(options={}, data)->

    data?.description or= "We are still working on #{data.name} provider."
    options.cssClass    = KD.utils.curry "provider-view", options.cssClass

    super options, data

    @header = new KDHeaderView
      title : @getData().name
      type  : "medium"

    @content = new KDView
      cssClass   : "content-view"

    @loader  = new KDLoaderView
      showLoader : @getOption('provider')?
      size       : width : 40

    provider = @getOption 'provider'

    @credentialBox  = new KDSelectBox
      name          : 'type'
      cssClass      : 'type-select hidden'
      selectOptions : [
        title: "Loading #{provider} credentials...", disabled: yes
      ]
      callback      : @bound 'showAvailablesFor'

    @content.addSubView @credentialBox

    @createAddCredentialForm()
    @createNewInstanceForm()

    @instanceController = new KDListViewController
      viewOptions       :
        cssClass        : 'instance-list'
        itemClass       : CloudInstanceItemView
        itemOptions     : { provider }
      wrapper           : no
      scrollView        : no
      noItemFoundWidget : new KDView
        partial         : "Instance list is not available at this time."

    @content.addSubView @instanceListView = @instanceController.getView()
    @instanceListView.hide()

    @instanceList = @instanceController.getListView()
    @instanceList.on "InstanceSelected", @bound 'createInstance'


  createInstance: (instance)->

    { provider } = @getOptions()
    { stack } = @getDelegate().getOptions()

    log instance, @_currentCredential, provider, stack

    @createInstanceForm.setClass 'in'
    @createInstanceForm.once "Submit", (data)=>

      KD.singletons.computeController.create {
        provider
        label        : data.title
        instanceType : instance.getData().name
        credential   : @_currentCredential
        stack        : stack._id
      }, (err, res)=>

        @createInstanceForm.unsetClass 'in'
        log err, res

        unless KD.showError err

          try

            packerTemplate = JSON.stringify res, null, 2

          catch e

            warn e; log res
            return new KDNotificationView
              title: "An error occured"

          new KDModalView
            content : "<pre>#{packerTemplate}</pre>"


  showAvailablesFor:(value)->

    info "Credential selected:", value

    if value is "_add_"
      @instanceListView.hide()
      @credentialBox.hide()
      @addCredentialForm.setClass 'in'
    else
      @showInstanceList value


  createNewInstanceForm:->

    @createInstanceForm = ComputeController.UI.generateCreateInstanceForm()

    @createInstanceForm.on "Cancel", =>
      @createInstanceForm.unsetClass 'in'
      @createInstanceForm.off 'Submit'

    @content.addSubView @createInstanceForm


  createAddCredentialForm:->

    provider = @getOption 'provider'

    @addCredentialForm?.destroy()
    @addCredentialForm = ComputeController.UI.generateAddCredentialFormFor provider

    @addCredentialForm.on "Cancel", =>
      @addCredentialForm.unsetClass 'in'
      value = @_currentCredential ? @_credOptions.first.value
      @credentialBox.setValue value
      @showAvailablesFor value
      @credentialBox.show()

    @addCredentialForm.on "CredentialAdded", (credential)=>
      @addCredentialForm.unsetClass 'in'
      @paneSelected yes, credential.publicKey
      @createAddCredentialForm()

    @content.addSubView @addCredentialForm


  viewAppended:->

    @on 'PaneDidShow', @bound 'paneSelected'

    @addSubView @header
    @addSubView new KDCustomHTMLView
      partial : "<p>#{@getData().description}</p>"
    @addSubView @loader
    @addSubView @content


  showInstanceList:(credentialKey)->
    provider = @getOption 'provider'

    @_currentCredential = credentialKey

    {computeController} = KD.singletons
    computeController.fetchAvailable
      provider   : provider
      credential : credentialKey
    , (err, instances)=>

      if err

        @instanceController.noItemView.updatePartial \
          if err.name is "NotImplemented"
            "Listing instances for #{provider} is not implemented yet."
          else
            "An error occured while listing instances for #{provider}."

        warn err

      else if instances

        @instanceController.replaceAllItems instances

      @instanceListView.show()


  paneSelected:(force = no, credentialKey)->

    return if @_laoded and not force

    @loader.show()

    provider = @getOption 'provider'

    {computeController} = KD.singletons
    computeController.credentialsFor provider, (err, credentials = [])=>

      @loader.hide()

      return if KD.showError err

      if credentials.length is 0
        @credentialBox.hide()
        @instanceListView.hide()
        @addCredentialForm.buttons.Cancel.hide()
        @addCredentialForm.setClass 'in'
        @_laoded = no
        return

      @_laoded = yes

      @_credentials = {}
      @_credOptions = []

      for cred in credentials
        @_credentials[cred.publicKey] = cred
        @_credOptions.push
          title: cred.title, value: cred.publicKey

      @_credOptions.push
        title: "Add new credential...", value: "_add_"

      @credentialBox.removeSelectOptions()
      @credentialBox.setSelectOptions
        "Select credential..." : @_credOptions

      @credentialBox.show()
      value = credentialKey ? @_credOptions.first.value
      @credentialBox.setValue value
      @showAvailablesFor value

      @instanceListView.show()
