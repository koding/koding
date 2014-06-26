KD.config.providers        =

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
        label              : "Secrets"
        placeholder        : "content of the client_secrets.xxxxx.json"
        type               : "textarea"
      privateKeyContent    :
        label              : "Private Key"
        placeholder        : "content of the xxxxx-privatekey.pem"
        type               : "textarea"
      # zone                 :
      #   label              : "Zone"
      #   placeholder        : "google zone"
      #   defaultValue       : "us-central1-a"

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

  rackspace                :
    title                  : "Rackspace Credential"
    description            : "Rackspace machines"
    credentialFields       :
      username             :
        label              : "Username"
        placeholder        : "username for rackspace"
      apiKey               :
        label              : "API Key"
        placeholder        : "rackspace api key"
