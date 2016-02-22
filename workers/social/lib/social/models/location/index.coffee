async       = require 'async'
KodingError = require '../../error'
{ Model, secure, signature } = require 'bongo'

module.exports = class JLocation extends Model

  @share()

  @set
    sharedEvents  :
      static      : []
      instance    : []
    sharedMethods :
      static      :
        importAll:
          (signature Function)
        importStates:
          (signature Function)
        one:
          (signature Object, Function)
        fetchStatesByCountryCode:
          (signature String, Function)
    schema        :
      zip         : String
      city        : String
      state       : String
      stateCode   : String
      county      : String
      countryCode : String

  @fetchStatesByCountryCode = (countryCode, callback) ->

    JLocationState = require './state'

    JLocationState.all { countryCode }, (err, states) ->
      if err
      then callback err
      else callback null,
        states.filter (state) -> !!state?.state
          .map (state) ->
            state     : state.state
            stateCode : state.stateCode
          .reduce (memo, value) ->
            memo[value.stateCode] =
              title: value.state
              value: value.stateCode
            return memo
          , {}

  @importStates = secure (client, callback) ->

    { delegate } = client.connection

    return callback new KodingError 'Access denied!'  unless delegate.can 'flag'

    JLocationState = require './state'

    collection = @getCollection()

    collection.distinct 'countryCode', {}, (err, countryCodes) =>
      return callback err  if err

      countries = countryCodes.map (countryCode) => (next) =>

        collection.distinct 'stateCode', { countryCode }, (err, stateCodes) =>
          return callback err  if err

          states = stateCodes.filter(Boolean).map (stateCode) => (nextState) =>

            @one { stateCode, countryCode }, (err, location) ->

              state = new JLocationState
                countryCode : location.countryCode
                stateCode   : location.stateCode
                state       : location.state

              state.save nextState

          async.seris states, -> next()

      async.series countries, -> callback null

  @importAll = secure (client, callback) ->

    { delegate } = client.connection

    return callback new KodingError 'Access denied!'  unless delegate.can 'flag'

    importer = (require 'koding-zips-importer')
      collectionName  : @getCollectionName()
      mongo           : @getClient()

    importer
      .once('error', callback)
      .once('end', => @importStates client, callback)
