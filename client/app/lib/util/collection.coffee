inherits_ = require '@koding/inherits-underscore'
_         = require 'lodash'

module.exports =

class Collection
  inherits_ Collection::

  MODELS_KEYNAME = 'models'

  constructor: (models) ->

    @models = _.map models, (model) ->
      if _.has model, MODELS_KEYNAME
        collection = new Collection model.models
        _.extend collection, _.omit model, MODELS_KEYNAME
        return collection
      return model
