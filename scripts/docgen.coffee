#!/usr/bin/env coffee

codo = require 'codo'
_    = require 'lodash'

generateSchema = (sample, required = no) ->

  # The MIT License (MIT) Copyright ⒞ 2016 Santtu Pajukanta
  # Taken from https://github.com/japsu/json-schema-by-example/blob/master/index.js
  # which is designed for es6 wasn't working with current
  # node version that we have and there was a missing
  # feature that we needed.
  #
  # This one provides `default` value of fields
  # in the schema so we can completely define the schema by providing
  # one simple example in the docs ~ GG
  #
  # TODO make a pull request to https://github.com/japsu/json-schema-by-example
  # or make a new package based on this one ~ GG
  rules = [

    [_.isNull,    (data)    -> { type: 'null',    default: data }],
    [_.isNumber,  (data)    -> { type: 'number',  default: data }],
    [_.isString,  (data)    -> { type: 'string',  default: data }],
    [_.isBoolean, (data)    -> { type: 'boolean', default: data }],
    [_.isRegExp,  (pattern) -> { type: 'string',  pattern }],

    [
      (example) -> _.isArray(example) and not example.length
    , ->
      { type: 'array' }
    ],

    [
      _.isArray
    , (items) -> {
        type: 'array', items: generateSchema items[0]
      }
    ],

    [
      _.isPlainObject
    , (object) ->
      obj = {
        type: 'object',
        properties: _.mapValues object, (sample) -> generateSchema sample
      }
      obj.required = _.keys object  if required
      return obj
    ]

  ]

  for [isMatch, makeSchema] in rules when isMatch sample
    return makeSchema sample

  throw new TypeError sample


compileApiExamples = (examples, methodOptions) ->

  for example, index in examples when example.title in ['api', 'return']
    try
      example.schema = generateSchema (JSON.parse example.code)
    catch e
      console.log 'Failed to parse example:', example, e

  return examples


module.exports = docGen = (path, files) ->

  errors = []
  doc    = {}

  unless path
    errors.push 'A valid path is required!'
    return { errors, doc }

  options = {}
  if files?.length > 0
    options.inputs = files

  environment = codo.parseProject path, options

  for klass in environment.allClasses()

    classDoc = klass.documentation ? {}

    if doc.hasOwnProperty klass.name
      errors.push "Duplicate Class #{klass.name}"
    else
      description = classDoc.comment  ? "Model #{klass.name}"
      parameters  = classDoc.params   ? []
      examples    = compileApiExamples (classDoc.examples ? [])

      doc[klass.name] = {
        description
        parameters
        examples
        instance : {}
        static   : {}
      }

    klass.methods.forEach (method) ->

      methodDoc = method.documentation ? {}
      kind = if method.kind is 'dynamic' then 'instance' else 'static'

      if doc[klass.name][kind].hasOwnProperty method.name
        errors.push "Duplicate method on #{klass.name}.#{kind}.#{method.name}"
      else
        doc[klass.name][kind][method.name] = {}

      methodOptions = methodDoc.options ? {}
      doc[klass.name][kind][method.name] =
        description : methodDoc.comment ? "Method #{klass.name}.#{method.name}"
        parameters  : methodDoc.params  ? []
        returns     : methodDoc.returns ? {}
        options     : methodOptions
        examples    : compileApiExamples (methodDoc.examples ? []), methodOptions


  return { errors, doc }


unless module.parent

  unless project = process.argv[2]
    console.log '''

      usage: docgen [path]
             where path refers to source code path for docs to generate

    '''
    process.exit 1

  try
    { errors, doc } = docGen project
  catch e
    console.log 'An error occured', e

  console.log JSON.stringify doc, ' ', 2
  if errors.length > 0
    console.log 'Has some errors:', JSON.stringify errors, ' ', 2

  process.exit()
