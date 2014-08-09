KD.config.providers        =

  custom                   :
    name                   : "Custom"
    link                   : "https://koding.com"
    title                  : "Custom Credential"
    description            : """Custom credentials can include meta
                               credentials for any service"""
    credentialFields       :
      credential           :
        label              : "Credential"
        placeholder        : "credential in JSON format"
        type               : "textarea"

  amazon                   :
    name                   : "Amazon Web Services"
    link                   : "https://aws.amazon.com"
    title                  : "AWS Credential"
    description            : "Amazon Web Services"
    credentialFields       :
      access_key           :
        label              : "Access Key"
        placeholder        : "aws access key"
      secret_key           :
        label              : "Secret Key"
        placeholder        : "aws secret key"
        type               : "password"

  koding                   :
    name                   : "Koding"
    link                   : "https://koding.com"
    title                  : "Koding Credential"
    description            : "Koding rulez."
    credentialFields       : {}

  google                   :
    name                   : "Google Compute Engine"
    link                   : "https://cloud.google.com/products/compute-engine/"
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
    name                   : "EngineYard"
    link                   : "https://www.engineyard.com/"
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
    name                   : "Digital Ocean"
    link                   : "https://digitalocean.com"
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
    name                   : "Rackspace"
    link                   : "http://www.rackspace.com"
    title                  : "Rackspace Credential"
    description            : "Rackspace machines"
    credentialFields       :
      username             :
        label              : "Username"
        placeholder        : "username for rackspace"
      apiKey               :
        label              : "API Key"
        placeholder        : "rackspace api key"
