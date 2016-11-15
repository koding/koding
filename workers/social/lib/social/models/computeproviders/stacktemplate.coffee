{ ObjectId, signature }  = require 'bongo'
{ Module, Relationship } = require 'jraphical'
KodingError              = require '../../error'
helpers                  = require './helpers'
async                    = require 'async'


module.exports = class JStackTemplate extends Module

  { permit }   = require '../group/permissionset'
  Validators   = require '../group/validators'
  { revive, checkTemplateUsage } = require './computeutils'

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

    sharedMethods     :

      static          :
        create        :
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
        clone         :
          (signature Function)
        generateStack :
          (signature Function)
        forceStacksToReinit :
          (signature String, Function)
        hasStacks     :
          (signature Function)

    sharedEvents      :
      static          : []
      instance        : []

    schema            :

      machines        : [ Object ]

      title           :
        type          : String
        required      : yes

      description     : String
      config          : Object

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
        content       : String
        sum           : String
        details       : Object
        rawContent    : String

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


  validateTemplate = (template, group, callback) ->

    limitConfig = helpers.getLimitConfig group
    return callback null  unless limitConfig.limit # No limit, no pain.

    ComputeProvider = require './computeprovider'
    ComputeProvider.validateTemplateContent template, limitConfig, callback


  @create = permit 'create stack template',

    success: revive

      shouldReviveClient   : yes
      shouldReviveProvider : no
      shouldFetchGroupLimit : yes

    , (client, data, callback) ->

      { group }    = client.r # we have revived JGroup and JUser here ~ GG
      { delegate } = client.connection

      unless data?.title
        return callback new KodingError 'Title required.'

      validateTemplate data.template, group, (err) ->
        return callback err  if err

        if data.config?
          data.config.groupStack = no

        stackTemplate = new JStackTemplate
          originId    : delegate.getId()
          group       : client.context.group
          title       : data.title
          config      : data.config      ? {}
          description : data.description ? ''
          machines    : data.machines    ? []
          accessLevel : data.accessLevel ? 'private'
          template    : generateTemplateObject \
            data.template, data.rawContent, data.templateDetails
          credentials : data.credentials

        stackTemplate.save (err) ->
          if err
          then callback new KodingError 'Failed to save stack template', err
          else callback null, stackTemplate


  @some$: permit 'list stack templates',

    success: (client, selector, options, callback) ->

      [options, callback] = [callback, options]  unless callback
      options ?= {}

      { delegate } = client.connection

      unless typeof selector is 'object'
        return callback new KodingError 'Invalid query'

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
      return callback no  if err or not group

      templateId = @getId()

      # TMS-1919: This is already written for multiple stacks, just a check
      # might be required ~ GG

      for stackTemplateId in group.stackTemplates ? []
        return callback yes  if templateId.equals stackTemplateId

      callback no


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

      @checkUsage (stackIsInUse) =>

        if stackIsInUse
          return callback new KodingError \
            "It's not allowed to delete in-use stack templates!", 'InUseByGroup'

        customCredentials = @getAt('credentials.custom') ? []
        { context: { group }, connection: { delegate: account } } = client

        notifyOptions =
          account: account
          group: group
          target: if @getAt('accessLevel') is 'group' then 'group' else 'account'

        @removeAndNotify notifyOptions, (err) ->
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

      @update query, (err) =>

        return callback err  if err
        return  unless group.slug

        JGroup = require '../group'
        JGroup.one { slug : group.slug }, (err, group_) =>
          return callback err, this  if err or not group_

          opts = { id, group: group.slug, change: query, timestamp: Date.now() }
          group_.sendNotification 'SetStackTemplateAccessLevel', opts
          callback err, this


  generateStack: permit

    advanced: [
      { permission: 'update own stack template', validateWith: Validators.own }
      { permission: 'update stack template' }
    ]

    success: revive

      shouldReviveClient   : yes
      shouldReviveProvider : no
      shouldFetchGroupLimit : yes

    , (client, callback) ->

      unless @getAt 'config.verified'
        return callback new KodingError 'Stack is not verified yet'

      { account, group, user } = client.r

      ComputeProvider = require './computeprovider'

      instanceCount = @machines?.length or 0
      change        = 'increment'

      details = { account, template: this }

      ComputeProvider.updateGroupResourceUsage {
        group, change, instanceCount, details
      }, (err) =>
        return callback err  if err

        checkTemplateUsage this, account, (err) =>
          return callback err  if err

          account.addStackTemplate this, (err) =>

            details = { account, user, group, client }
            details.template = this

            ComputeProvider.generateStackFromTemplate details, {}, callback


  update$: permit

    advanced: [
      { permission: 'update own stack template', validateWith: Validators.own }
      { permission: 'update stack template' }
    ]

    success: revive

      shouldReviveClient   : yes
      shouldReviveProvider : no
      shouldFetchGroupLimit : yes

    , (client, data, callback) ->

      { group }    = client.r
      { delegate } = client.connection

      # It's not allowed to change a stack template group or owner
      delete data.originId
      delete data.group

      # Update template sum if template update requested
      { template, templateDetails, rawContent } = data

      async.series [
        (next) =>
          return next()  unless template?

          validateTemplate template, group, (err) =>
            return next err  if err

            data.template = generateTemplateObject \
              template, rawContent, templateDetails

            # Keep the existing template details if not provided
            if not templateDetails?
              data.template.details = @getAt 'template.details'

            delete data.templateDetails
            delete data.rawContent

            # Keep last updater info in the template details
            data.template.details.lastUpdaterId = delegate.getId()

            data['meta.modifiedAt'] = new Date

            next()
        (next) =>
          query = { $set: data }

          notifyOptions =
            account : delegate
            group   : group.slug
            target  : if @accessLevel is 'group' then 'group' else 'account'

          @updateAndNotify notifyOptions, query, next
      ], (err, results) => callback err, this


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
      { permission: 'update own stack template' }
      { permission: 'update stack template' }
    ]

    success: (client, callback) ->

      cloneData         =
        title           : "#{@getAt 'title'} - clone"
        description     : @getAt 'description'

        config          : @getAt 'config'
        machines        : @getAt 'machines'
        credentials     : @getAt 'credentials'

        template        : @getAt 'template.content'
        rawContent      : @getAt 'template.rawContent'
        templateDetails : @getAt 'template.details'

      cloneData.config           ?= {}
      cloneData.config.clonedFrom = @getId()
      cloneData.config.clonedSum = @getAt 'template.sum'

      { custom } = cloneData.credentials or {}
      custom    ?= []

      if custom.length > 0
        cloneCustomCredentials client, custom, (err, creds) ->
          return callback new KodingError 'Failed to clone credentials'  if err
          cloneData.credentials.custom = creds
          JStackTemplate.create client, cloneData, callback
      else
        JStackTemplate.create client, cloneData, callback


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
