{ ObjectId, signature, secure } = require 'bongo'
{ Module, Relationship } = require 'jraphical'

_ = require 'lodash'
async = require 'async'
helpers = require './helpers'
KodingError = require '../../error'
clientRequire = require '../../clientrequire'


module.exports = class JStackTemplate extends Module

  { slugify } = require '../../traits/slugifiable'
  { permit }  = require '../group/permissionset'
  Validators  = require '../group/validators'

  ComputeProvider = require './computeprovider'

  {
    revive
    PROVIDERS
    flattenPayload
    checkTemplateUsage
  } = require './computeutils'

  @trait __dirname, '../../traits/protected'
  @trait __dirname, '../../traits/notifiable'


  @share()

  @set

    softDelete        : yes

    permissions       :

      'create stack template'     : ['member', 'moderator']
      'list stack templates'      : ['member', 'moderator']

      'delete own stack template' : ['member', 'moderator']
      'update own stack template' : ['member', 'moderator']

      'delete stack template'     : []
      'update stack template'     : []

      'force stacks to reinit'    : []

      'check own stack usage'     : ['member']
      'check stack usage'         : []

    # we need a compound index here
    # since bongo is not supporting them
    # we need to manually define following:
    #
    #   - originId, group, slug (unique)
    #

    sharedMethods     :

      static          :
        create        :
          (signature Object, Function)
        samples       :
          (signature Object, Function)
        preview       :
          (signature Object, Function)
        one           : [
          (signature Object, Function)
          (signature Object, Object, Function)
        ]
        some          : [
          (signature Object, Function)
          (signature Object, Object, Function)
        ]

      instance        :
        delete        :
          (signature Function)
        setAccess     :
          (signature String, Function)
        update        :
          (signature Object, Function)
        build         :
          (signature Object, Function)
        clone         :
          (signature Function)
        verify        :
          (signature Function)
        generateStack :
          (signature Object, Function)
        forceStacksToReinit :
          (signature String, Function)
        hasStacks     :
          (signature Function)

    sharedEvents      :
      static          : []
      instance        : []

    schema            :

      machines        :
        type          : [ Object ]
        _description  : 'Machines found in stack template'
        default       : -> []

      title           :
        type          : String
        required      : yes
        _description  : 'Title of this stack template'

      slug            :
        type          : String
        required      : yes
        _description  : 'Unique slug of stack template'

      description     :
        type          : String
        _description  : 'Stack template description'

      config          :
        type          : Object
        _description  : 'Private config data for stack template'

      accessLevel     :
        type          : String
        enum          : ['Wrong level specified!',
          ['private', 'group', 'public']
        ]
        default       : 'private'

      originId        :
        type          : ObjectId
        required      : yes

      meta            : require 'bongo/bundles/meta'

      group           :
        type          : String
        required      : yes

      template        :
        content       :
          type        : String
          _description: 'Stack template content in JSON format'
        sum           :
          type        : String
          _description: 'Sum of stringified JSON content, auto-generated'
        details       :
          type        : Object
          _description: 'Details data for stack template'
        rawContent    :
          type        : String
          _description: 'Stack template content in YAML format'

      # Identifiers of JCredentials
      # structured like following;
      #  { Provider: [ JCredential.identifier ] }
      #  ---
      #  {
      #    aws: [123123, 123124]
      #    github: [234234]
      #  }
      credentials     :
        type          : Object
        default       : -> {}


  generateRawContentFrom = (template) ->

    { jsonToYaml } = clientRequire 'app/lib/util/stacks/yamlutils'
    return jsonToYaml template


  generateTemplateObject = (content, rawContent, details) ->

    crypto     = require 'crypto'
    content    = ''  unless typeof content is 'string'
    rawContent = ''  unless typeof rawContent is 'string'

    details ?= {}

    return {
      content
      details
      rawContent
      sum: crypto.createHash 'sha1'
        .update content
        .digest 'hex'
    }


  updateConfigForTemplate = (config, template) ->

    supportedProviders = Object.keys (require './computeprovider').providers

    providersParser    = clientRequire 'app/lib/util/stacks/providersparser'
    requirementsParser = clientRequire 'app/lib/util/stacks/requirementsparser'

    config.groupStack       ?= no
    config.requiredData      = requirementsParser template
    config.requiredProviders = providersParser template, supportedProviders

    return config


  parsePlanResponse = (res) ->

    supportedProviders = Object.keys (require './computeprovider').providers
    parseTerraformOutput = clientRequire \
      'app/lib/util/stacks/parseterraformoutput'

    return (parseTerraformOutput res, supportedProviders) ? []


  generateSlugFromTitle = ({ originId, group, title, index }, callback) ->

    unless title
      return callback null

    slug = _title = if index? then "#{title} #{index}" else title
    slug = slugify slug

    if index >= 20
      return callback new KodingError \
        'Too many occurrences, please provide a different title'

    JStackTemplate.count { originId, group, slug }, (err, count) ->
      return callback err  if err?

      if count is 0
        callback null, { slug, title: _title }
      else
        index ?= 0
        index += 1
        generateSlugFromTitle { originId, group, title, index }, callback


  validateTemplateData = (data, options, callback) ->

    unless data
      return callback new KodingError 'Template data is required!'

    { config = {}, title, template, rawContent, templateDetails } = data

    if template and rawContent
      template = generateTemplateObject template, rawContent, templateDetails
      if config
        config = updateConfigForTemplate config, template.rawContent
        title ?= generateTemplateTitle config.requiredProviders[0]

    { originId, group } = options
    limitConfig = helpers.getLimitConfig group
    group       = group.slug

    generateSlugFromTitle { group, originId, title }, (err, res = {}) ->

      return callback err  if err

      { slug, title } = res
      replacements = { template, config, title, slug }

      if not data.template     or \
         not limitConfig.limit or \
             limitConfig.limit is 'unlimited' # No limit, no pain.
        return callback null, replacements

      ComputeProvider = require './computeprovider'
      ComputeProvider.validateTemplateContent \
        data.template, limitConfig, (err) ->
          return callback err  if err
          callback null, replacements


  generateTemplateTitle = (provider) ->

    { capitalize } = require 'lodash'
    getPokemonName = clientRequire 'app/lib/util/getPokemonName'

    return "#{getPokemonName()} #{capitalize provider} Stack"


  # creates a JStackTemplate with requested content
  #
  # @param {Object} data
  #   data object describes new JStackTemplate
  #
  # @option data [String] template template's content as stringified JSON
  # @option data [String] title template's title
  # @option data [Object] credentials template's credentials
  # @option data [Object] config template's config
  #
  # @return {JStackTemplate} created JStackTemplate instance
  #
  # @example api
  #
  #   {
  #     "template": "{\"provider\": {\"aws\": {}}}",
  #     "title": "My AWS template",
  #     "credentials": {},
  #     "config": {}
  #   }
  #
  @create = ->
  @create = permit

    advanced: [
      {
        permission   : 'create stack template',
        validateWith : Validators.group.custom 'membersCanCreateStacks'
      }
    ]

    success: revive

      shouldReviveClient    : yes
      shouldReviveProvider  : no
      shouldFetchGroupLimit : yes

    , (client, data, callback) ->

      { group }    = client.r # we have revived JGroup and JUser here ~ GG
      { delegate } = client.connection
      originId     = delegate.getId()
      options      = { group, originId }

      if not data.template
        return callback new KodingError 'Template content is required!'

      if not data.rawContent
        { err, content } = generateRawContentFrom data.template
        if err
          return callback new KodingError \
            'Failed to parse template', 'ParseFailed', err.message
        data.rawContent = content

      validateTemplateData data, options, (err, replacements) ->
        return callback err  if err

        stackTemplate = new JStackTemplate
          originId    : originId
          group       : client.context.group
          description : data.description ? ''
          machines    : data.machines    ? []
          accessLevel : data.accessLevel ? 'private'
          credentials : data.credentials ? {}

        stackTemplate.slug     = replacements.slug
        stackTemplate.title    = replacements.title

        stackTemplate.config   = replacements.config
        stackTemplate.template = replacements.template

        stackTemplate.save (err) ->
          if err
          then callback new KodingError 'Failed to save stack template', err
          else callback null, stackTemplate


  ###
  returns sample stack template for given provider

  @param {Object} options
    options for fetching sample template

  @option options [String] provider provider name for fetching sample
  @option options [Boolean] useDefaults if it's true templates will be provided with default values

  @return {Object} stacktemplate sample in json and yaml format with default values

  @example api

    {
      "provider": "aws",
      "useDefaults": true
    }

  @example return

    {
      "json": "{}",
      "yaml": "--",
      "defaults": {
        "userInputs": {}
      }
    }

  ###
  @samples = ->
  @samples = permit 'list stack templates',

    success: revive

      shouldReviveClient    : no
      shouldReviveProvider  : yes

    , (client, options, callback) ->

      { provider, useDefaults = no } = options

      if useDefaults
      then callback null, provider.templateWithDefaults
      else callback null, provider.template


  # returns preview stack template for given template and custom variables
  #
  # @param {Object} options
  #   options for generating template preview
  #
  # @option options [String] template content
  # @option options [Object] custom variables
  #
  # @return {Object} stacktemplate preview in provided format
  #
  # @example api
  #
  #   {
  #     "template": "Hello ${var.koding_user_username} -- ${var.custom_foo}",
  #     "custom": {"foo": "bar"}
  #   }
  #
  # @example return
  #
  #   {
  #     "template": "Hello gokmen -- bar",
  #     "errors": {},
  #     "warnings": {}
  #   }
  #
  @preview = ->
  @preview = permit 'list stack templates',

    success: revive

      shouldReviveClient    : yes
      shouldReviveProvider  : no

    , (client, options, callback) ->

      generatePreview = clientRequire 'app/lib/util/stacks/generatepreview'

      { template, custom } = options
      { account, group }   = client.r

      accountWrapper =
        fetchFromUser: (data, callback) ->
          account.fetchFromUser client, data, callback

      generatePreview {
        account: accountWrapper, group, template, custom
      }, callback


  getNotifyOptions: (client) ->

    { group } = client.context
    { connection: { delegate } } = client

    return {
      account : delegate
      group   : group
      target  : if @getAt('accessLevel') is 'group' then 'group' else 'account'
    }


  @some$: permit 'list stack templates',

    success: (client, selector, options, callback) ->

      [options, callback] = [callback, options]  unless callback
      options ?= {}

      { delegate } = client.connection

      unless typeof selector is 'object'
        return callback new KodingError 'Invalid query'

      # By default return stack templates that requester owns
      if (Object.keys selector).length is 0
        selector = { originId: delegate.getId() }

      selector.$and ?= []
      selector.$and.push
        $or : [
          { originId      : delegate.getId() }
          { accessLevel   : 'public' }
          {
            $and          : [
              accessLevel : 'group'
              group       : client.context.group
            ]
          }
        ]

      @some selector, options, (err, templates) ->
        callback err, templates


  @one$: permit 'list stack templates',

    success: (client, selector, options, callback) ->

      [options, callback] = [callback, options]  unless callback

      options ?= {}
      options.limit = 1

      @some$ client, selector, options, (err, templates) ->
        [template] = templates ? []
        callback err, template


  checkUsage: (callback) ->

    slug   = @getAt 'group'

    JGroup = require '../group'
    JGroup.one { slug }, (err, group) =>
      console.error "Group #{slug} not found!"  unless group

      # If there is an error with group fetching, we assume that
      # this stack template is not in use by that group to not prevent
      # removal of non-used stack templates ~ GG
      return callback null  if err or not group

      templateId = @getId()

      for stackTemplateId in group.stackTemplates ? []
        if templateId.equals stackTemplateId
          return callback new KodingError \
            'Stack Template is currently in use by the Team', 'InUseByGroup'

      callback null


  removeCustomCredentials = (client, credentials, callback) ->

    JCredential = require './credential'
    queue       = []

    credentials.forEach (identifier) -> queue.push (next) ->
      JCredential.fetchByIdentifier client, identifier, (err, credential) ->
        if not err and credential
        then credential.delete client, -> next()
        else next()

    async.series queue, -> callback null


  delete: permit

    advanced: [
      { permission: 'delete own stack template', validateWith: Validators.own }
      { permission: 'delete stack template' }
    ]

    success: (client, callback) ->

      @checkUsage (err) =>
        return callback err  if err

        customCredentials = @getAt('credentials.custom') ? []

        @removeAndNotify (@getNotifyOptions client), (err) ->
          return callback err  if err

          # delete custom credentials if exists ~ GG
          removeCustomCredentials client, customCredentials, callback


  setAccess: permit
    advanced: [
      { permission: 'update own stack template', validateWith: Validators.own }
      { permission: 'update stack template' }
    ]

    success: revive

      shouldReviveClient   : yes
      shouldReviveProvider : no
      shouldFetchGroupLimit : no

    , (client, accessLevel, callback) ->

      { group } = client.r
      query = { $set: { accessLevel } }
      id = @getId()
      currentAccessLevel = @getAt 'accessLevel'

      @update query, (err) =>

        return callback err  if err

        if currentAccessLevel is accessLevel or not group.slug
          return callback null, this

        JGroup = require '../group'
        JGroup.one { slug : group.slug }, (err, group_) =>
          return callback err, this  if err or not group_

          opts = { id, group: group.slug, change: query, timestamp: Date.now() }
          group_.sendNotification 'SharedStackTemplateAccessLevel', opts
          callback err, this


  generateStack: permit

    advanced: [
      {
        permission   : 'update stack template',
        validateWith : Validators.group.custom 'membersCanCreateStacks'
      }
      {
        permission   : 'update own stack template',
        validateWith : Validators.own
      }
    ]

    success: revive

      shouldReviveClient    : yes
      shouldReviveProvider  : no
      shouldFetchGroupLimit : yes

    , (client, options, callback) ->

      { account, group, user } = client.r

      instanceCount = (@getAt 'machines')?.length or 0
      template = this

      queue = [

        (next) =>

          unless @getAt 'config.verified'
            if options.verify
            then @verify client, next
            else next new KodingError 'Stack is not verified yet'
          else next null

        (next) =>

          change  = 'increment'
          ComputeProvider.updateGroupResourceUsage {
            group, change, instanceCount, details: { account, template }
          }, (err) =>
            return next err  if err
            checkTemplateUsage this, account, (err) =>
              return next err  if err
              account.addStackTemplate this, next

      ]

      async.series queue, (err) ->
        return callback err  if err

        details = { account, user, group, client, template }

        ComputeProvider.generateStackFromTemplate details, {}, (err, res) ->

          resourceOptions = {
            details : { account, template }
            change  : 'decrement'
            group, instanceCount
          }

          if err
            return ComputeProvider.updateGroupResourceUsage resourceOptions, ->
              callback err

          { machines = [] } = res?.results ? []
          if failedMachines = (machines.filter (m) -> m.err).length
            resourceOptions.instanceCount = failedMachines
            resourceOptions.instanceOnly = yes
            ComputeProvider.updateGroupResourceUsage resourceOptions, (err) ->
              callback err, res
          else
            callback null, res


  update$: permit

    advanced: [
      { permission: 'update own stack template', validateWith: Validators.own }
      { permission: 'update stack template' }
    ]

    success: revive

      shouldReviveClient    : yes
      shouldReviveProvider  : no
      shouldFetchGroupLimit : yes

    , (client, data, callback) ->

      { group }    = client.r
      { delegate } = client.connection
      originId     = delegate.getId()
      options      = { originId, group }

      updateAndNotify = (query) =>
        @updateAndNotify (@getNotifyOptions client), query, (err, results) =>
          callback err, this

      # Create a clone of provided data to work on it around
      data = _.clone data

      # It's not allowed to change a stack template group or owner
      delete data.originId
      delete data.group

      delete data.title  if data.title is @getAt 'title'

      # Update template sum if template update requested
      { config, title, template, templateDetails, rawContent } = data

      validateTemplateData data, options, (err, replacements) =>
        return callback err  if err

        if template
          # update template object, sum, rawContent etc.
          data.template = replacements.template

          # Keep the existing template details if not provided
          if not templateDetails?
            data.template.details = @getAt 'template.details'

          # Keep last updater info in the template details
          data.template.details.lastUpdaterId = delegate.getId()

        if config
          # add required providers/fields on to config from template
          data.config = replacements.config

        delete data.templateDetails
        delete data.rawContent
        delete data.slug

        if title
          data.title = replacements.title
          data.slug  = replacements.slug

        data['meta.modifiedAt'] = new Date

        if template and originalId = data.config?.clonedFrom

          # update clonedSum information in the template, if it is exists
          JStackTemplate.one$ client, { _id: originalId }, (err, template) ->
            if template and not err
              if template.template.sum is data.template.sum
                data.config.clonedSum = template.template.sum
            updateAndNotify { $set: data }

        else
          updateAndNotify { $set: data }


  cloneCustomCredentials = (client, credentials, callback) ->

    JCredential = require './credential'
    clonedCreds = []
    queue       = []

    credentials.forEach (identifier) -> queue.push (next) ->
      JCredential.fetchByIdentifier client, identifier, (err, credential) ->
        if not err and credential
          credential.clone client, (err, cloneCredential) ->
            if err
              console.warn 'Clone failed:', err
            else
              clonedCreds.push cloneCredential.identifier
            next()
        else
          next()

    async.series queue, -> callback null, clonedCreds


  clone: permit

    advanced: [
      {
        permission   : 'update own stack template',
        validateWith : Validators.group.custom 'membersCanCreateStacks'
      }
      {
        permission   : 'update own stack template',
        validateWith : Validators.own
      }
    ]

    success: (client, options, callback) ->

      [ options, callback ] = [ callback, options ]  unless callback
      options ?= {}

      { connection: { delegate }, context: { group } } = client

      hasAccess = yes

      if @getAt('accessLevel') is 'private'
        hasAccess = delegate.getId().equals @getAt('originId')

      else if @getAt('accessLevel') is 'group'
        if @getAt('group') isnt group
          hasAccess = no

      unless hasAccess
        return callback new KodingError 'Access denied'

      cloneData         =
        slug            : @getAt 'slug'
        title           : options.title ? "#{@getAt 'title'} - clone"
        description     : options.description ? @getAt 'description'

        config          : @getAt 'config'
        machines        : @getAt 'machines'
        credentials     : @getAt 'credentials'

        template        : @getAt 'template.content'
        rawContent      : @getAt 'template.rawContent'
        templateDetails : @getAt 'template.details'

      cloneData.config           ?= {}
      cloneData.config.clonedFrom = @getId()
      cloneData.config.clonedSum  = @getAt 'template.sum'

      cloneData.config = updateConfigForTemplate \
        cloneData.config, cloneData.rawContent

      { custom } = cloneData.credentials or {}
      custom    ?= []

      if custom.length > 0
        cloneCustomCredentials client, custom, (err, creds) ->
          return callback new KodingError 'Failed to clone credentials'  if err
          cloneData.credentials.custom = creds
          JStackTemplate.create client, cloneData, callback
      else
        JStackTemplate.create client, cloneData, callback


  build: permit

    advanced: [
      { permission: 'update own stack template', validateWith: Validators.own }
      { permission: 'update stack template' }
    ]

    success: (client, payload, callback) ->

      unless @getAt 'config.verified'
        return callback new KodingError 'Stack needs to be verified first'

      # TODO: GitHub Payload specific updates, this can be moved some other
      # place as a middleware ~GG
      options = {}
      if payload?.after
        options.title = "#{@getAt 'title'} - #{payload.after[..10]}"
        if payload.repository?.url?
          options.description = \
            "Auto build for #{payload.repository.url}@#{payload.after}"

      @clone client, options, (err, clonedTemplate) ->
        return callback err  if err
        unless clonedTemplate
          return callback new KodingError 'Failed to clone template'

        clonedTemplate.generateStack client, {}, (err, res) ->
          return callback err  if err
          unless res.stack
            return callback new KodingError 'Failed to generate stack'

          { stack: generatedStack } = res
          stackId = generatedStack.getId()
          provider = (generatedStack.getAt 'config.requiredProviders')[0]
          variables = flattenPayload payload

          Kloud = require './kloud'
          Kloud.buildStack client, { stackId, provider, variables }, callback


  getProvider: ->

    # TODO: add multiple provider support here ~GG
    provider = @getAt 'config.requiredProviders.0'

    unless provider or not PROVIDERS[provider]
      return [ new KodingError 'Provider is not supported' ]

    return [ null, provider ]


  verify$: permit

    advanced: [
      { permission: 'update own stack template', validateWith: Validators.own }
      { permission: 'update stack template' }
    ]

    success: (client, callback) ->
      @verify client, callback


  verify: (client, callback) ->

    stackTemplateId = @getAt '_id'

    [ err, provider ] = @getProvider()
    return callback err  if err

    @verifyCredentials client, (err) =>

      if err
        return callback new KodingError \
          'Credentials verification failed', 'CredentialError', err

      noMachines = ->
        callback new KodingError \
          'Nothing to verify, template has no machines'

      Kloud = require './kloud'
      Kloud.checkTemplate client, { stackTemplateId, provider }, (err, res) =>
        return callback err  if err
        return noMachines()  if not res or not res.machines?.length

        machines = parsePlanResponse res
        return noMachines()  unless machines.length

        query = { $set: { machines, 'config.verified': true } }
        @updateAndNotify (@getNotifyOptions client), query, (err) =>
          return callback err  if err
          callback null, this


  verifyCredentials: (client, callback) ->

    @fetchProviderCredential client, (err, credential) ->
      return callback err  if err

      credential.isBootstrapped client, (err, bootstrapped) ->
        return callback err   if err
        return callback null  if bootstrapped

        credential.bootstrap client, callback


  fetchProviderCredential: (client, callback) ->

    [ err, provider ] = @getProvider()
    return callback err  if err

    # TODO: add multiple provider support here ~GG
    unless identifier = @getAt "credentials.#{provider}.0"
      return callback new KodingError \
        "No credential found for #{provider} provider"

    JCredential = require './credential'
    JCredential.one$ client, identifier, (err, credential) ->
      if err or not credential
        return callback new KodingError 'Credential is not accessible'

      callback null, credential


  forceStacksToReinit: permit 'force stacks to reinit',

    success: (client, message, callback) ->

      ComputeProvider = require './computeprovider'
      ComputeProvider.forceStacksToReinit this, message, callback


  hasStacks: permit

    advanced: [
      { permission: 'check own stack usage', validateWith: Validators.own }
      { permission: 'check stack usage' }
    ]

    success: (client, callback) ->

      JComputeStack = require '../stack'
      JComputeStack.some {
        baseStackId: @_id
        'status.state': { $ne: 'Destroying' }
      }, { limit: 1 }, (err, stacks) ->
        result = stacks?.length > 0
        callback err, result


# Base StackTemplate example for koding group
###

KD.remote.api.JStackTemplate.create({
  title: "Default stack",
  description: "Koding's default stack template for new users",
  config: {
     "KODINGINSTALLER" : "v1.0",
     "KODING_BASE_PACKAGES" : "mc nodejs python sl screen",
     "DEBIAN_FRONTEND" : "noninteractive"
  },
  machines: [
    {
      "label" : "koding-vm-0",
      "provider" : "koding",
      "instance_type" : "t2.nano",
      "provisioners" : [
          "devrim/koding-base"
      ],
      "region" : "us-east-1",
      "source_ami" : "ami-a6926dce"
    }
  ],
}, function(err, template) {
  return console.log(err, template);
});

Default Template ---

{
    "_id" : ObjectId("53925a609b76835748c0c4fd"),
    "meta" : {
        "modifiedAt" : ISODate("2014-05-15T02:04:11.033Z"),
        "createdAt" : ISODate("2014-05-15T02:04:11.032Z"),
        "likes" : 0
    },
    "accessLevel" : "private",
    "title" : "Default stack",
    "description" : "Koding's default stack template for new users",
    "config" : {
        "KODINGINSTALLER" : "v1.0",
        "KODING_BASE_PACKAGES" : "mc nodejs python sl",
        "DEBIAN_FRONTEND" : "noninteractive"
    },
    "machines" : [
        {
            "label" : "VM1 from Koding",
            "provider" : "koding",
            "instance_type" : "t2.nano",
            "provisioners" : [
                "devrim/koding-base"
            ],
            "region" : "us-east-1",
            "source_ami" : "ami-a6926dce"
        },
        {
            "label" : "Test VM #2 on DO",
            "provider" : "digitalocean",
            "instanceType" : "512mb",
            "credential" : "dce2e21086218f7eb83b865d63cd50b6",
            "provisioners" : [
                "devrim/koding-base"
            ],
            "image" : "ubuntu-13-10-x64",
            "region" : "sfo1",
            "size" : "512mb"
        },
        {
            "label" : "Test VM #3 on DO",
            "provider" : "digitalocean",
            "instanceType" : "512mb",
            "credential" : "dce2e21086218f7eb83b865d63cd50b6",
            "provisioners" : [
                "devrim/koding-base"
            ],
            "image" : "ubuntu-13-10-x64",
            "region" : "sfo1",
            "size" : "512mb"
        }
    ],
    "group" : "koding",
    "originId" : ObjectId("5196fcb0bc9bdb0000000011")
}

###
