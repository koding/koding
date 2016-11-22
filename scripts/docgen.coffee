#!/usr/bin/env coffee

codo = require 'codo'
generateSchema = require 'generate-schema'

compileSample = (sample) ->
  schema = generateSchema.json sample
  delete schema['$schema']
  for own field of schema.properties
    schema.properties[field].default = sample[field]
  return schema


compileApiExamples = (examples) ->

  for example, index in examples when example.title is 'api'
    try
      example.schema = compileSample JSON.parse example.code
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

      doc[klass.name][kind][method.name] =
        description : methodDoc.comment ? "Method #{klass.name}.#{method.name}"
        parameters  : methodDoc.params  ? []
        returns     : methodDoc.returns ? {}
        options     : methodDoc.options ? {}
        examples    : compileApiExamples (methodDoc.examples ? [])


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
