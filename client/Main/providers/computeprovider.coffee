class ComputeProvider extends KDObject

  @vendors                   =

    custom                   :
      title                  : "Custom Credential"
      description            : """Custom credentials can include meta
                                 credentials for any service"""
      credentialFields       :
        credential           :
          label              : "Credential"
          placeholder        : "credential in JSON format"
          type               : "textarea"

    amazon                   :
      title                  : "AWS Credential"
      description            : "Amazon Web Services"
      credentialFields       :
        accessKeyId          :
          label              : "Access Key"
          placeholder        : "aws access key"
        secretAccessKey      :
          label              : "Secret Key"
          placeholder        : "aws secret key"
          type               : "password"
        region               :
          label              : "Region"
          placeholder        : "aws region"
          defaultValue       : "us-east-1"

    koding                   :
      title                  : "Koding Credential"
      description            : "Koding rulez."
      credentialFields       :
        username             :
          label              : "Username"
          placeholder        : "koding username"
        password             :
          label              : "Password"
          placeholder        : "koding password"
          type               : "password"

    google                   :
      title                  : "Google Cloud Credential"
      description            : "Google compute engine"
      credentialFields       :
        projectId            :
          label              : "Project Id"
          placeholder        : "project id in gce"
        clientSecretsContent :
          label              : "Client secrets"
          placeholder        : "content of the client_secrets.xxxxx.json"
          type               : "textarea"
        privateKeyContent    :
          label              : "Private Key"
          placeholder        : "content of the xxxxx-privatekey.pem"
          type               : "textarea"
        zone                 :
          label              : "Zone"
          placeholder        : "google zone"
          defaultValue       : "us-central1-a"

    engineyard               :
      title                  : "EngineYard Credential"
      description            : "EngineYard"
      credentialFields       :
        accountId            :
          label              : "Account Id"
          placeholder        : "account id in engineyard"
        secret               :
          label              : "Secret"
          placeholder        : "engineyard secret"
          type               : "password"

    digitalocean             :
      title                  : "Digitalocean Credential"
      description            : "Digitalocean droplets"
      credentialFields       :
        clientId             :
          label              : "Client Id"
          placeholder        : "client id in digitalocean"
        apiKey               :
          label              : "API Key"
          placeholder        : "digitalocean api key"

  @showProvidersModal = ->
    new KDModalView
      title        : 'Add Virtual Machine'
      cssClass     : 'vendor-modal'
      view         : new VendorView
      width        : 800
      overlay      : yes
      buttons      :
        create     :
          title    : "Create"
          style    : "modal-clean-green"
          callback : =>

  @generateAddCredentialFormFor = (vendor)->

    fields          =
      title         :
        label       : "Title"
        placeholder : "title for this credential"

    Vendors = ComputeProvider.vendors

    Object.keys(Vendors[vendor].credentialFields).forEach (field)->
      fields[field] = _.clone Vendors[vendor].credentialFields[field]
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
          vendor, title, meta: data
        }, (err, credential)=>

          Save.hideLoader()

          unless KD.showError err
            @emit "CredentialAdded", credential

  @credentialsFor = (vendor, callback)->
    KD.remote.api.JCredential.some { vendor }, callback
