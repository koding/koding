class ComputeProvider extends KDObject

  requiresLogin = do -> ({ message }, fn) -> ->

    return unless KD.isLoggedIn()
      new KDNotificationView
        title: message

    fn()

  @providers = KD.config.providers

  @credentialsFor = (provider, callback)->
    KD.remote.api.JCredential.some { provider }, callback

  @fetchAvailable = (options, callback)->
    KD.remote.api.ComputeProvider.fetchAvailable options, callback

  @fetchExisting = (options, callback)->
    KD.remote.api.ComputeProvider.fetchExisting options, callback

  @fetchStacks = (callback)->

    if @stacks
      callback null, @stacks
      info "Stacks returned from cache."
      return

    KD.remote.api.JStack.some {}, (err, stacks = [])->
      return callback err  if err?
      callback null, ComputeProvider.stacks = stacks


  @create = (options, callback)->
    KD.remote.api.ComputeProvider.create options, callback

  @showProvidersModal = requiresLogin
    message: "You need to login to create a new machine."
  , ->
    new KDModalView
      title        : 'Add Virtual Machine'
      cssClass     : 'provider-modal'
      view         : new ProviderView
      width        : 800
      height       : 600
      overlay      : yes
      buttons      :
        create     :
          title    : "Create"
          style    : "modal-clean-green"
          callback : =>
            info arguments

  @generateAddCredentialFormFor = (provider)->

    fields          =
      title         :
        label       : "Title"
        placeholder : "title for this credential"

    Providers = ComputeProvider.providers

    Object.keys(Providers[provider].credentialFields).forEach (field)->
      fields[field] = _.clone Providers[provider].credentialFields[field]
      fields[field].required = yes

    return form = new KDFormViewWithFields
      cssClass     : "form-view"
      fields       : fields
      buttons      :
        Save       :
          title    : "Add credential"
          type     : "submit"
          style    : "solid green medium"
          loader   :
            color  : "#444444"
          callback : -> @hideLoader()
        Cancel     :
          style    : "solid medium"
          callback : -> form.emit "Cancel"
      callback     : (data)->

        log "Here we go", data

        { Save } = @buttons
        Save.showLoader()

        { title } = data
        delete data.title

        KD.remote.api.JCredential.create {
          provider, title, meta: data
        }, (err, credential)=>

          Save.hideLoader()

          unless KD.showError err
            @emit "CredentialAdded", credential
