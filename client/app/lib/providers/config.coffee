globals = require 'globals'
isProd  = globals.config.environment is 'production'
baseURL = globals.config.domains.base

module.exports = globals.config.providers =

  custom                   :
    name                   : 'Custom'
    link                   : "https://#{baseURL}"
    title                  : 'Custom Credential'
    color                  : '#b9c0b8'
    description            : '''Custom credentials can include meta
                               credentials for any service'''
    listText               : """
                              You're currently using these custom data in your
                              stack templates, you can change their contents
                              without touching stack templates.
                            """
    credentialFields       :
      credential           :
        label              : 'Credential'
        placeholder        : 'credential in JSON format'
        type               : 'textarea'

  aws                      :
    name                   : 'Amazon Web Services'
    link                   : 'https://aws.amazon.com'
    title                  : 'AWS'
    color                  : '#F9A900'
    description            : 'Amazon Web Services'
    advancedFields         : [
                              'subnet', 'sg', 'vpc',
                              'ami', 'acl', 'cidr_block',
                              'igw', 'rtb'
                             ]
    credentialFields       :
      access_key           :
        label              : 'Access Key ID'
        placeholder        : 'aws access key'
        attributes         :
          autocomplete     : if isProd then 'off' else 'on'
      secret_key           :
        label              : 'Secret Access Key'
        placeholder        : 'aws secret key'
        attributes         :
          autocomplete     : if isProd then 'off' else 'on'
      region               :
        label              : 'Region'
        type               : 'selection'
        placeholder        : 'Region'
        defaultValue       : 'us-east-1'
        values             : [
          { title: 'US East (N. Virginia) (us-east-1)',         value: 'us-east-1' }
          { title: 'US West (Oregon) (us-west-2)',              value: 'us-west-2' }
          { title: 'US West (N. California) (us-west-1)',       value: 'us-west-1' }
          { title: 'EU (Ireland) (eu-west-1)',                  value: 'eu-west-1' }
          { title: 'EU (Frankfurt) (eu-central-1)',             value: 'eu-central-1' }
          { title: 'Asia Pacific (Singapore) (ap-southeast-1)', value: 'ap-southeast-1' }
          { title: 'Asia Pacific (Sydney) (ap-southeast-2)',    value: 'ap-southeast-2' }
          { title: 'Asia Pacific (Tokyo) (ap-northeast-1)',     value: 'ap-northeast-1' }
          { title: 'South America (Sao Paulo) (sa-east-1)',     value: 'sa-east-1' }
        ]

  koding                   :
    name                   : 'Koding'
    link                   : 'https://koding.com'
    title                  : 'Koding'
    color                  : '#50c157'
    description            : 'Koding rulez.'
    credentialFields       : {}

  managed                  :
    name                   : 'Managed VMs'
    link                   : "https://#{baseURL}"
    title                  : 'Managed VM'
    color                  : '#6d119e'
    description            : 'Use your power.'
    credentialFields       : {}

  google                   :
    name                   : 'Google Compute Engine'
    link                   : 'https://cloud.google.com/products/compute-engine/'
    title                  : 'Google Cloud'
    color                  : '#357e99'
    description            : 'Google compute engine'
    credentialFields       :
      projectId            :
        label              : 'Project Id'
        placeholder        : 'project id in gce'
      clientSecretsContent :
        label              : 'Secrets'
        placeholder        : 'content of the client_secrets.xxxxx.json'
        type               : 'textarea'
      privateKeyContent    :
        label              : 'Private Key'
        placeholder        : 'content of the xxxxx-privatekey.pem'
        type               : 'textarea'
      # zone                 :
      #   label              : "Zone"
      #   placeholder        : "google zone"
      #   defaultValue       : "us-central1-a"

  azure                    :
    name                   : 'Azure'
    link                   : 'https://azure.microsoft.com/'
    title                  : 'Azure'
    color                  : '#ec06be'
    description            : 'Azure'
    credentialFields       :
      accountId            :
        label              : 'Account Id'
        placeholder        : 'account id in azure'
      secret               :
        label              : 'Secret'
        placeholder        : 'azure secret'
        type               : 'password'

  digitalocean             :
    name                   : 'Digital Ocean'
    link                   : 'https://digitalocean.com'
    title                  : 'Digitalocean'
    color                  : '#7abad7'
    description            : 'Digitalocean droplets'
    credentialFields       :
      clientId             :
        label              : 'Client Id'
        placeholder        : 'client id in digitalocean'
      apiKey               :
        label              : 'API Key'
        placeholder        : 'digitalocean api key'

  rackspace                :
    name                   : 'Rackspace'
    link                   : 'http://www.rackspace.com'
    title                  : 'Rackspace'
    color                  : '#d8deea'
    description            : 'Rackspace machines'
    credentialFields       :
      username             :
        label              : 'Username'
        placeholder        : 'username for rackspace'
      apiKey               :
        label              : 'API Key'
        placeholder        : 'rackspace api key'

  softlayer                :
    name                   : 'Softlayer'
    link                   : 'http://www.softlayer.com'
    title                  : 'Softlayer'
    color                  : '#B52025'
    description            : 'Softlayer resources'
    credentialFields       :
      username             :
        label              : 'Username'
        placeholder        : 'username for softlayer'
      api_key              :
        label              : 'API Key'
        placeholder        : 'softlayer api key'

  userInput                :
    name                   : 'User Input'
    title                  : 'User Input'
    listText               : '''
                            Here you can change user input fields that you define
                            in your stack scripts. When you delete these,
                            make sure that you update the stack scripts that
                            these are used in. Otherwise you may experience
                            unwanted results while building your stacks.
                            '''
    credentialFields       : {}
  vagrant                  :
    name                   : 'Vagrant'
    link                   : 'http://www.vagrantup.com'
    title                  : 'Vagrant on Local'
    color                  : '#B52025'
    description            : 'Local provisioning with Vagrant'
    credentialFields       :
      queryString          :
        label              : 'Kite ID'
        placeholder        : 'ID for my local machine kite'
