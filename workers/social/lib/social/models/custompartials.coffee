{Model} = require 'bongo'

module.exports = class JCustomPartials extends Model

  {signature} = require 'bongo'
  @share()

  @set
    indexes         :
      partialType   : 'sparse'
    schema          :
      name          : String
      partialType   : String
      partial       : String
      isActive      : Boolean
      viewInstance  : String

    sharedMethods :
      static      :
        create    :
          (signature Object, Function)
        some      :
          (signature Object, Object, Function)
      instance     :
        update     :
          (signature Object, Function)
        remove     :
          (signature Function)

  @create =(data, callback) ->
    customPartial = new JCustomPartials data
    customPartial.save (err)->
      return callback err if err
      return callback null, customPartial
