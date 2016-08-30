_ = require 'lodash'
normalizr = require 'normalizr'

# makeNamespace: accepts 1 or more string and returns a new function which can
# be used to generage strings with namespaces:
#   withNamespace = makeNamespace 'koding', 'redux', 'bongo'
#
#   withNamespace('LOAD') === 'koding/redux/bongo/LOAD'
exports.makeNamespace = makeNamespace = (args...) -> (str) ->
  args.concat([str]).join '/'

# ASYNC_ACTION_VERBS: Default async action verbs that will be used for
# generating async action types.
ASYNC_ACTION_VERBS = ['BEGIN', 'SUCCESS', 'FAIL']

# expandActionType: takes a string, returns an array with verbs appended to the string.
#   expandActionType 'LOAD'
#   => {BEGIN: 'LOAD_BEGIN', SUCCESS: 'LOAD_SUCCESS', FAIL: 'LOAD_FAIL'}
#   => # used default verbs.
#
#   expandActionType 'LOAD', ['FOO, 'BAR']
#   => {FOO: 'LOAD_FOO', BAR: 'LOAD_BAR'}
exports.expandActionType = expandActionType = (type, verbs = ASYNC_ACTION_VERBS) ->
  verbs.reduce (types, verb) ->
    types[verb] = [type, verb].join '_'
    return types
  , {}

exports.normalize = (args...) ->
  normalized = normalizr.normalize args...

  return _.assign normalized, { first: (key) -> first normalized.entities[key] }


first = (obj) -> _.values(obj)[0]

exports.defineSchema = (name, definitions) ->
  isArray = Array.isArray name

  [name] = name  if isArray

  rootSchema = new normalizr.Schema name
  definitions and rootSchema.define definitions

  return if isArray then normalizr.arrayOf(rootSchema) else rootSchema
