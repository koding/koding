{Module} = require 'jraphical'

module.exports = class JVocabulary extends Module

  @share()

  {daisy} = require 'bongo'
  {KodingError} = require '../error'

  {permit} = require './group/permissionset'

  Validators = require './group/validators'
  {Inflector} = require 'bongo'

  @trait __dirname, '../traits/protected'

  @set
    sharedMethods   :
      static        : ['create']
      instance      : ['remove', 'modify']
    schema          :
      title         : String
      description   : String
      exclusive     :
        type        : Boolean
        default     : no
      group         :
        type        : String
        validate    : require('./name').validateName
      collectionName:
        type        : String
        default     : ->
          {name} = require './tag'
          "#{Inflector.pluralize name}__#{@group.replace /-/g, '_'}"
    relationships   :
      tag           :
        targetType  : 'JTag'
        as          : 'vocabulary'
    permissions     :
      'create vocabularies'     : ['moderator']
      'edit vocabularies'       : ['moderator']
      'delete vocabularies'     : ['moderator']
      'edit own vocabularies'   : ['moderator']
      'delete own vocabularies' : ['moderator']

  @create$ = permit 'create vocabularies'
    success:(client, formData, callback)->
      formData.group = client.context.group
      @create formData, callback

  @create = (formData, callback)->
    JGroup = require './group'
    vocabulary = new this
      title       : formData.title
      description : formData.description
      group       : formData.group
    queue = [
      ->
        vocabulary.save (err)->
          if err then callback err
          else queue.next()
    ]
    if formData.group
      queue.push ->
        JGroup.one slug: formData.group, (err, group)->
          if err then callback err
          else unless group?
            callback new KodingError "Unknown group: #{formData.group}"
          else
            group.addVocabulary vocabulary, (err)->
              if err then callback err
              else queue.next()
    queue.push -> callback null, vocabulary
    daisy queue

  remove$: permit
    advanced: [
      { permission: 'delete vocabularies' }
      { permission: 'delete own vocabularies', validateWith: Validators.own }
    ]
    success:(client, callback)-> @remove callback

  modify: permit
    advanced: [
      { permission: 'edit vocabularies' }
      { permission: 'edit own vocabularies', validateWith: Validators.own }
    ]
    success:(client, formData, callback)->
      formData.group = client.content.group
      @update { $set:formData }, callback