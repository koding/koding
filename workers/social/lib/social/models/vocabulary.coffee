{Module} = require 'jraphical'

module.exports = class JVocabulary extends Module

  {daisy} = require 'bongo'
  {KodingError} = require '../error'

  @trait __dirname, '../traits/protected'

  @set
    schema          :
      title         : String
      description   : String
      exclusive     :
        type        : Boolean
        default     : no
    relationships   :
      tag           :
        targetType  : 'JTag'
        as          : 'vocabulary'
    permissions     : [
      'create vocabularies'
      'edit vocabularies'
      'delete vocabularies'
      'edit own vocabularies'
      'delete own vocabularies'
    ]

  @create =(client, formData, callback)->
    JGroup = require './group'
    vocabulary = new @
      title       : formData.title
      description : formData.description
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

