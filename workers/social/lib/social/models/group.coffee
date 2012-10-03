{Module} = require 'jraphical'

module.exports = class JGroup extends Module

  {Inflector, ObjectRef} = require 'bongo'

  @set
    indexes         :
      slug          : 'unique'
    sharedMethods   :
      static        : ['create']
    schema          :
      title         :
        type        : String
        required    : yes
      description   : String
      avatar        : String
      slug          :
        type        : String
        default     : -> Inflector.dasherize @title.toLowerCase()
      privacy       :
        type        : String
        enum        : ['invalid privacy type', ['public', 'private']]
      visibility    :
        type        : String
        enum        : ['invalid visibility type', ['visible', 'hidden']]
      parent        : ObjectRef
    relationships   :
      member        :
        targetType  : 'JAccount'
        as          : 'group'
      moderator     :
        targetType  : 'JAccount'
        as          : 'group'
      admin         :
        targetType  : 'JAccount'
        as          : 'group'
      application   :
        targetType  : 'JApp'
        as          : 'owner'
      vocabulary    :
        targetType  : 'JVocabulary'
        as          : 'owner'
      subgroup      :
        targetType  : 'JGroup'
        as          : 'parent'
      tag           :
        targetType  : 'JTag'
        as          : 'tag'

  @create =(client, formData, callback)->
    group = new @ formData
    group.save (err)->
      if err
        callback err
      else
        group.addMember client, (err)->
          if err
            callback err
          else
            group.addAdmin client, (err)->
              if err
                callback err
              else
                callback null, group