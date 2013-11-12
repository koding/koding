{Module} = require 'jraphical'

class JPaymentPack extends Module

  { permit } = require '../group/permissionset'

  @share()

  @set
    sharedMethods   :
      static        : [
        'create'
      ]
      instance      : [
        'modify'
        'fetchProducts'
        'updateProducts'
      ]
    schema          :
      title         :
        type        : String
        required    : yes
      description   : String
      group         :
        type        : String
        required    : yes
      quantities    :
        type        : Object
        default     : -> {}      
      tags          : (require './schema').tags
      sortWeight    : Number
    relationships   :
      product       :
        targetType  : 'JPaymentProduct'
        as          : 'plan product'

  @create = (groupSlug, formData, callback) ->

    { title, description } = formData

    JGroup = require '../group'

    pack = new this {
      title
      description
      group       : groupSlug
    }

    pack.save (err) ->
      return callback err  if err

      JGroup.one slug: groupSlug, (err, group) ->
        return callback err  if err

        group.addPack pack, (err) ->
          return callback err  if err

          callback null, pack

  @create$ = permit 'manage products',
    success: (client, formData, callback) ->
      @create client.context.group, formData, callback

  modify:->

  fetchProducts:->

  updateProducts:->
