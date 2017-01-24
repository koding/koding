Bongo = require 'bongo'
Table = require 'cli-table'
read = require 'read'

{ join: joinPath } = require 'path'

KONFIG = require 'koding-config-manager'

koding = new Bongo
  root   : __dirname
  mongo  : "mongodb://#{ KONFIG.mongo }"
  models : '../../workers/social/lib/social/models'

normalizeDbIndexes = (rawIndexes) ->
  rawIndexes.reduce (memo, index) ->
    k = getKeyOf index.key
    return memo  if k is '_id'
    memo[k] = Object.keys(index).filter (key) ->
      key in ['unique', 'sparse', 'dropDups']
    if index.key[k] is -1
      memo[k].push 'descending'
    else
      memo[k].push 'ascending'
    memo
  , {}

normalizeCodeIndex = (rawIndex) ->
  normalized =
    if Array.isArray rawIndex
    then rawIndex
    else
      [
        if 'string' is typeof rawIndex
        then rawIndex
        else
          if rawIndex is 1
          then 'ascending'
          else 'descending'
      ]
  normalized.push 'ascending'  unless 'descending' in normalized
  normalized

normalizeCodeIndexes = (rawIndexes) ->
  indexes = Object.keys(rawIndexes).reduce (memo, key) ->
    memo[key] = normalizeCodeIndex rawIndexes[key]
    memo
  , {}

doCompare = (dbIndex, codeIndex) ->
  return no  for attr, i in dbIndex when codeIndex[i] isnt attr
  return yes

mustCompare = (name, key, dbIndexes, codeIndexes) ->
  codeIndex = codeIndexes[key]?.sort()
  dbIndex = dbIndexes[key]?.sort()

  if not codeIndex? or not dbIndex?
    if codeIndex?
      missingFromDatabase[name] ?= {}
      missingFromDatabase[name][key] = codeIndex
    if dbIndex?
      missingFromCode[name] ?= {}
      missingFromCode[name][key] = dbIndex
    return

  unless doCompare dbIndex, codeIndex
    different[name] ?= {}
    different[name][key] = { dbIndex, codeIndex }

getKeyOf = (key) ->
  return k  for own k of key

formatTable = (collection, head, callback) ->
  (
    for own className, indexes of collection
      table = new Table { head }
      rows = Object.keys(indexes).map (key) ->
        callback key, indexes[key]
      table.push rows...
      """
      #{ className }:\n#{ table }
      """
  ).join '\n\n'

formatMissingItems = (collection) ->
  formatTable collection, ['Field', 'Index'],
    (field, values) ->
      [
        field
        values.join ', '
      ]

formatDifferentItems = (collection) ->
  formatTable collection, ['Field', 'DB Index', 'Code Index'],
    (field, { dbIndex, codeIndex }) ->
      [
        field
        dbIndex.join ', '
        codeIndex.join ', '
      ]

getReport = ({ missingFromDatabase, missingFromCode, different }) ->
  none = '(none)\n'.green
  """
  #{ "These indexes are found in the database, but are missing from the code:".bold.red }

  #{ (formatMissingItems missingFromCode) or none }

  #{ "These indexes are found in the code, but are missing from the database:".bold.red }

  #{ (formatMissingItems missingFromDatabase) or none }

  #{ "These indexes were found in both places, but were not compatible:".bold.red }

  #{ (formatDifferentItems different) or none }
  """

maybe = (obj) ->
  if Object.keys(obj).length is 0
  then null
  else obj

convertToMongoIndex = (field, bongoIndex) ->
  bongoIndex.reduce (memo, attr) ->
    switch attr
      when 'ascending'
        memo.field[field] = 1
      when 'descending'
        memo.field[field] = -1
      when 'unique'
        memo.options.unique = true
      when 'sparse'
        memo.options.sparse = true
      when 'dropDups'
        memo.options.dropDups = true
    memo
  , { field: {}, options: { background: true } }

quit = ->
  console.log 'Finished!'.bold.green
  process.nextTick -> process.exit 0

updateCallback = (err, ok) ->
  if err or not ok or ok.toLowerCase().charAt(0) isnt 'y'
    console.log "Didn't update the database".cyan
    process.exit 1

  for own name, indexes of missingFromDatabase
    collection = koding.models[name].getCollection()

    i = 0; j = 0

    for own fieldName, index of indexes
      ++i

      { field, options } = convertToMongoIndex fieldName, index

      collection.ensureIndex field, options, (err) ->
        throw err  if err

        quit()  if i is ++j

done = ->
  console.log getReport { missingFromDatabase, missingFromCode, different }
  if Object.keys(missingFromDatabase).length
    read
      prompt:
        '''
        Would you like to update the database with the indexes from the code?
        '''
          .cyan
          .bold
      default: 'y'
    , updateCallback
  else
    process.exit 0

missingFromCode = {}
missingFromDatabase = {}
different = {}

koding.once 'dbClientReady', ->
  i = 0; j = 0
  for own name, konstructor of koding.models when konstructor.prototype instanceof Bongo.Model
    do (name, konstructor) ->
      ++i
      konstructor.getCollection().indexes (err, indexes) ->
        throw err  if err
        ++j

        dbIndexes = maybe normalizeDbIndexes indexes
        codeIndexes = maybe normalizeCodeIndexes konstructor.indexes_ or {}

        if not dbIndexes? or not codeIndexes?
          if dbIndexes?
            missingFromCode[name] = dbIndexes
          if codeIndexes?
            missingFromDatabase[name] = codeIndexes
          done()  if i is j
          return

        for own field, index of dbIndexes
          mustCompare name, field, dbIndexes, codeIndexes

        done()  if i is j
