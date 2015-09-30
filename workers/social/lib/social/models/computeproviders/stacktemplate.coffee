{ ObjectId, signature }  = require 'bongo'
{ Module, Relationship } = require 'jraphical'
KodingError              = require '../../error'


module.exports = class JStackTemplate extends Module

  { permit }   = require '../group/permissionset'
  Validators   = require '../group/validators'

  @trait __dirname, '../../traits/protected'

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

    sharedEvents      :
      static          : [ ]
      instance        : [
        { name : 'updateInstance' }
      ]

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


  generateTemplateObject = (content, details) ->

    crypto   = require 'crypto'
    content  = ''  unless typeof content is 'string'
    details ?= {}

    return {
      content
      details
      sum: crypto.createHash 'sha1'
        .update content
        .digest 'hex'
    }


  @create = permit 'create stack template',

    success: (client, data, callback) ->

      { delegate } = client.connection

      unless data?.title
        return callback new KodingError 'Title required.'

      stackTemplate = new JStackTemplate
        originId    : delegate.getId()
        group       : client.context.group
        title       : data.title
        config      : data.config      ? {}
        description : data.description ? ''
        machines    : data.machines    ? []
        accessLevel : data.accessLevel ? 'private'
        template    : generateTemplateObject data.template, data.templateDetails
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

      options ?= {}
      options.limit = 1

      @some$ client, selector, options, callback


  delete: permit

    advanced: [
      { permission: 'delete own stack template', validateWith: Validators.own }
      { permission: 'delete stack template' }
    ]

    success: (client, callback) -> @remove callback


  setAccess: permit

    advanced: [
      { permission: 'update own stack template', validateWith: Validators.own }
      { permission: 'update stack template' }
    ]

    success: (client, accessLevel, callback) ->

      @update { $set: { accessLevel } }, callback


  update$: permit

    advanced: [
      { permission: 'update own stack template', validateWith: Validators.own }
      { permission: 'update stack template' }
    ]

    success: (client, data, callback) ->

      { delegate } = client.connection

      # It's not allowed to change a stack template group or owner
      delete data.originId
      delete data.group

      # Update template sum if template update requested
      { template, templateDetails } = data
      if template?
        data.template = generateTemplateObject template, templateDetails

        # Keep the existing template details if not provided
        if not templateDetails?
          data.template.details = @getAt 'template.details'

        # Keep last updater info in the template details
        data.template.details.lastUpdaterId = delegate.getId()

      @update { $set: data }, (err) -> callback err


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
      "instanceType" : "t2.micro",
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
            "instanceType" : "t2.micro",
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


