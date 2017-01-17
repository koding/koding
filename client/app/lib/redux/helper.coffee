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
#
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


# defineSchema: helper around `new normalizr.Schema`
#
# instead of creating schema first and defining the schemas later, this helper
# this accepts definitions to determine what kind of definitions it will have,
#
# Normally we have to define schemas individually:
#
#   customer = new normalizr.Schema 'customer'
#   sources = new normalizr.Schema 'sources'
#   subscriptions = new normalizr.Schema 'subscriptions'
#   plan = new normalizr.Schema 'plan'
#
#   # first define subscription
#   subscription.define { plan }
#
#   # then define customer
#   customer.define
#     sources:
#       data: normalizr.arrayOf(sources)
#     subscriptions:
#       data: normalizr.arrayOf(subscriptions)
#
#   # normalize with customer schema
#   normalizr.normalize(data, customer)
#
# This might get tedious, so this helper provides a convinient way:
#
#   schema = defineSchema 'customer',
#     sources:
#       data: defineSchema 'sources', []
#     subscriptions:
#       data: defineSchema 'subscriptions', [{
#         plan: defineSchema 'plan'
#       }]
#
#   normalizr.normalize(data, schema) # => same as the one above
#
# Simply it can be read as:
#
#   - Define a schema and call it 'customer'
#   - Data prop of its sources will be an array of payment sources (credit cards)
#   - Data prop of its subscriptions will be an array of subscriptions
#
# What is it doing?
#
# an example of customer response would be something like this:
#
#   customerResponse = {
#     id: 'cus_1',
#     account_balance: 0,
#     sources: {
#       data: [
#         { id: 'src_1', last4: '...', ... },
#         { id: 'src_2', last4: '...', ... },
#       ]
#     },
#     subscriptions: {
#       data: [
#         { id: 'sub_1', plan: { ... }, ... },
#         { id: 'sub_2', plan: { ... }, ... },
#       ]
#     }
#   }
#
# Using normalizr.normalize with the result of this helper would result in a
# flatten map with all the special definitions extracted into an `entities`
# object:
#
#   # let's use the customer `schema` we defined earlier:
#   normalized = normalizr.normalize(customerResponse, schema)
#   {
#     entities: {
#       customer: { <-- entity is extracted
#         cus_1: {
#           id: 'cus_1'
#           sources: {
#             data: ['src_1, 'src_2']
#           },
#           subscriptions: {
#             data: ['sub_1, 'sub_2']
#           }
#         }
#       },
#       sources: { <-- entity is extracted
#         src_1: { id: 'src_1', last4: '...', ... }, <-- mapped with id fields.
#         src_2: { id: 'src_2', last4: '...', ... },
#       },
#       subscriptions: { <-- entity is extracted
#         sub_1: { id: 'sub_1', plan: { ... }, ... },
#         sub_2: { id: 'sub_2', plan: { ... }, ... },
#       },
#     }
#   }
#
exports.defineSchema = (name, definitions) ->

  isArray = Array.isArray definitions

  [definitions] = definitions  if isArray

  rootSchema = new normalizr.schema.Entity name

  rootSchema.define definitions  if definitions

  return if isArray
  then new normalizr.schema.Array rootSchema
  else rootSchema
