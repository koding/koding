globals = require 'globals'
isProd  = globals.config.environment is 'production'
baseURL = globals.config.domains.base
replaceUserInputs = require 'app/util/stacks/replaceuserinputs'

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
    title                  : 'AWS Credential'
    supported              : yes
    enabled                : yes
    color                  : '#e69d01'
    description            : 'Amazon Web Services'
    instanceTypes          : require './instance-types/aws'
    defaultTemplate        : replaceUserInputs require './templates/aws'
    advancedFields         : [
                              'subnet', 'sg', 'vpc',
                              'ami', 'acl', 'cidr_block',
                              'igw', 'rtb'
                             ]
    attributeMapping       :
      image                : 'ami'
      instance_type        : 'instance_type'
      storage_size         : 'storage'
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

  vagrant                  :
    name                   : 'Vagrant'
    link                   : 'http://www.vagrantup.com'
    title                  : 'Vagrant Credential'
    color                  : '#6768a9'
    supported              : yes
    enabled                : 'beta'
    defaultTemplate        : replaceUserInputs require './templates/vagrant'
    instanceTypes          : require './instance-types/vagrant'
    description            : 'Local provisioning with Vagrant'
    credentialFields       :
      queryString          :
        label              : 'Kite ID'
        placeholder        : 'ID for my local machine kite'
        attributes         :
          autocomplete     : if isProd then 'off' else 'on'

  managed                  :
    name                   : 'Managed VMs'
    link                   : "https://#{baseURL}"
    title                  : 'Managed VM'
    color                  : '#6d119e'
    description            : 'Use your power.'
    instanceTypes          : null
    credentialFields       : {}

  google                   :
    name                   : 'Google Compute Engine'
    link                   : 'https://cloud.google.com/compute/'
    title                  : 'Google Cloud Credential'
    color                  : '#357e99' # dunno
    supported              : yes
    enabled                : 'beta'
    defaultTemplate        : replaceUserInputs require './templates/google'
    description            : 'Google compute engine'
    instanceTypes          : require './instance-types/gce'
    attributeMapping       :
      image                : 'disk.0.image' # getting the first disk image ~ GG
      instance_type        : 'machine_type'
      region               : 'zone'
    credentialFields       :
      project              :
        label              : 'Project ID'
        placeholder        : 'ID of Project'
        attributes         :
          autocomplete     : if isProd then 'off' else 'on'
      credentials          :
        label              : 'Service Account'
        placeholder        : 'Provide content of key in JSON format'
        type               : 'textarea'
      region               :
        label              : 'Region'
        type               : 'selection'
        placeholder        : 'Select target region' # dunno
        defaultValue       : 'us-central1'
        values             : [
          { title: 'Western US (us-west1)',         value: 'us-west1' }
          { title: 'Central US (us-central1)',      value: 'us-central1' }
          { title: 'Eastern US (us-east1)',         value: 'us-east1' }
          { title: 'Western Europe (europe-west1)', value: 'europe-west1' }
          { title: 'Eastern Asia (asia-east1)',     value: 'asia-east1' }
        ]

  digitalocean             :
    name                   : 'Digital Ocean'
    link                   : 'https://digitalocean.com'
    title                  : 'Digital Ocean Credential'
    color                  : '#0080ff'
    supported              : yes
    slug                   : 'do'
    enabled                : 'beta'
    defaultTemplate        : replaceUserInputs require './templates/digitalocean'
    instanceTypes          : require './instance-types/do'
    description            : 'Digital Ocean droplets'
    attributeMapping       :
      image                : 'image'
      instance_type        : 'size'
      region               : 'region'
    credentialFields       :
      access_token         :
        label              : 'Access Token'
        placeholder        : 'Digital Ocean access token'
        attributes         :
          autocomplete     : if isProd then 'off' else 'on'

  azure                    :
    name                   : 'Azure'
    link                   : 'https://azure.microsoft.com/'
    title                  : 'Azure Credential'
    color                  : '#6391a9'
    supported              : yes
    enabled                : 'beta'
    defaultTemplate        : replaceUserInputs require './templates/azure'
    description            : 'Azure'
    instanceTypes          : require './instance-types/azure'
    advancedFields         : ['password', 'ssh_key_thumbprint']
    attributeMapping       :
      image                : 'image'
      instance_type        : 'size'
      region               : 'location'
    credentialFields       :
      publish_settings     :
        label              : 'Publish Settings'
        placeholder        : 'publish settings for azure'
        type               : 'textarea'
      subscription_id      :
        label              : 'Subscription ID'
        placeholder        : 'subscription id of azure account'
        attributes         :
          autocomplete     : if isProd then 'off' else 'on'
      password             :
        label              : 'Password'
        placeholder        : 'default password for instances'
        type               : 'password'
        attributes         :
          autocomplete     : 'new-password'
      ssh_key_thumbprint   :
        label              : 'SSH Key'
        placeholder        : 'ssh key thumb print'
        attributes         :
          autocomplete     : 'off'
      location             :
        label              : 'Location'
        type               : 'selection'
        placeholder        : 'location / region'
        defaultValue       : 'East US 2'
        values             : [
          { title: 'West US 2 (west-us-2)',             value: 'West US 2' }
          { title: 'West Central US (west-central-us)', value: 'West Central US' }
          { title: 'Quebec City (canada-east)',         value: 'Canada East' }
          { title: 'Sao Paulo State (brazil-south)',    value: 'Brazil South' }
          { title: 'Tokyo, Saitama (japan-east)',       value: 'Japan East' }
          { title: 'Virginia (east-us)',                value: 'East US' }
          { title: 'Virginia (east-us-2)',              value: 'East US 2' }
          { title: 'Iowa (central-us)',                 value: 'Central US' }
          { title: 'Illinois (north-central-us)',       value: 'North Central US' }
          { title: 'Texas (south-central-us)',          value: 'South Central US' }
          { title: 'California (west-us)',              value: 'West US' }
          { title: 'Virginia (us-gov-virginia)',        value: 'US Gov Virginia' }
          { title: 'Iowa (us-gov-iowa)',                value: 'US Gov Iowa' }
          { title: 'Toronto (canada-central)',          value: 'Canada Central' }
          { title: 'Arizona (us-gov-arizona)',          value: 'US Gov Arizona' }
          { title: 'Texas (us-gov-texas)',              value: 'US Gov Texas' }
          { title: 'Ireland (north-europe)',            value: 'North Europe' }
          { title: 'Netherlands (west-europe)',         value: 'West Europe' }
          { title: 'Frankfurt (germany-central)',       value: 'Germany Central' }
          { title: 'Magdeburg (germany-northeast)',     value: 'Germany Northeast' }
          { title: 'Cardiff (uk-west)',                 value: 'UK West' }
          { title: 'London (uk-south-)',                value: 'UK South ' }
          { title: 'Singapore (southeast-asia)',        value: 'Southeast Asia' }
          { title: 'Kong (east-asia-hong)',             value: 'East Asia Hong' }
          { title: 'New South, Wales (australia-east)', value: 'Australia East' }
          { title: 'Victoria (australia-southeast)',    value: 'Australia Southeast' }
          { title: 'Pune (central-india)',              value: 'Central India' }
          { title: 'Mumbai (west-india)',               value: 'West India' }
          { title: 'Chennai (south-india)',             value: 'South India' }
          { title: 'Osaka (japan-west)',                value: 'Japan West' }
          { title: 'Shanghai (china-east)',             value: 'China East' }
          { title: 'Beijing (china-north)',             value: 'China North' }
          { title: 'Seoul (korea-central)',             value: 'Korea Central' }
        ]
      storage              :
        label              : 'Storage'
        type               : 'selection'
        placeholder        : 'storage replication type'
        defaultValue       : 'Standard_LRS'
        values             : [
          { title: 'Locally redundant storage (LRS)',            value: 'Standard_LRS' }
          { title: 'Zone-redundant storage (ZRS)',               value: 'Standard_ZRS' }
          { title: 'Geo-redundant storage (GRS)',                value: 'Standard_GRS' }
          { title: 'Read-access geo-redundant storage (RA-GRS)', value: 'Standard_RAGRS' }
          { title: 'Premium Locally redundant storage (P_LRS)',  value: 'Premium_LRS' }
        ]

  marathon                 :
    name                   : 'Marathon'
    link                   : 'https://mesosphere.github.io/marathon/'
    title                  : 'Marathon Credential'
    color                  : '#03b19e'
    supported              : yes
    enabled                : 'beta'
    defaultTemplate        : replaceUserInputs require './templates/marathon'
    description            : 'A container orchestration platform for Mesos and DC/OS'
    advancedFields         : [
      'request_timeout',
      'deployment_timeout',
      'basic_auth_password',
      'basic_auth_user'
    ]
    credentialFields       :
      url                  :
        label              : 'URL'
        placeholder        : 'url of marathon application'
      basic_auth_user      :
        label              : 'Auth User'
        placeholder        : 'basic auth user for marathon'
        required           : no
      basic_auth_password  :
        label              : 'Auth Password'
        type               : 'password'
        placeholder        : 'basic auth password for marathon'
        required           : no
      request_timeout      :
        label              : 'Req. Timeout'
        placeholder        : 'request timeout value in seconds'
      deployment_timeout   :
        label              : 'Deploy Timeout'
        placeholder        : 'deploy timeout value in seconds'

  softlayer                :
    name                   : 'Softlayer'
    link                   : 'http://www.softlayer.com'
    title                  : 'Softlayer Credential'
    color                  : '#B52025'
    supported              : yes
    enabled                : 'beta'
    defaultTemplate        : replaceUserInputs require './templates/softlayer'
    instanceTypes          : require './instance-types/softlayer'
    description            : 'Softlayer Virtual Guest'
    attributeMapping       :
      image                : 'image'
      instance_type        : 'size'
      region               : 'region'
    credentialFields       :
      username             :
        label              : 'User ID'
        placeholder        : 'user id including prefix (like SL or IBM)'
      api_key              :
        label              : 'API Key'
        placeholder        : 'softlayer api key'
        attributes         :
          autocomplete     : if isProd then 'off' else 'on'

  rackspace                :
    name                   : 'Rackspace'
    link                   : 'http://www.rackspace.com'
    title                  : 'Rackspace'
    color                  : '#d8deea'
    supported              : yes
    enabled                : no
    description            : 'Rackspace machines'
    credentialFields       :
      username             :
        label              : 'Username'
        placeholder        : 'username for rackspace'
        attributes         :
          autocomplete     : if isProd then 'off' else 'on'
      apiKey               :
        label              : 'API Key'
        placeholder        : 'rackspace api key'
        attributes         :
          autocomplete     : if isProd then 'off' else 'on'

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

  _getSupportedProviders   : ->
    (Object.keys this).filter (provider) =>
      this[provider].supported
