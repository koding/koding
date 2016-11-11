require 'coffee-cache'

bongo = require './servers/lib/server/bongo'

HEADER = """
---
swagger: '2.0'
info:
  version: 0.0.1
  title: Koding API

paths:
  /-/version:
    get:
      responses:
        200:
          description: OK
  /-/api/remote/jaccount.one:
    post:
      responses:
        200:
          description: OK
          schema:
            $ref: "#/definitions/JAccount"

"""

parseType = (type) ->

  type = type.toLowerCase()
  type = 'string'  if type is 'objectid'
  type = 'string'  if type is 'date'
  type = 'object'  if type is 'meta'

  return type


getProps = (prop, def, field) ->

  try
    prop.format = 'date'  if prop.type is 'Date'
    prop.type = parseType prop.type
    prop.items.type = parseType prop.items.type  if prop.items?.type
  catch e
    console.log 'Failed on field:', field
    throw e

  if prop.required
    def.required ?= []
    def.required.push field
    delete prop.required

  return prop


generateDefinition = (model) ->

  schema = model.describeSchema()
  def    = { type: 'object' }
  props  = {}

  for field, prop of schema

    if 'type' not in Object.keys prop
      props[field] = { properties: {} }
      for subfield, subprop of prop
        props[field].properties[subfield] = getProps subprop, def, field
    else
      props[field] = getProps prop, def, field

  def.properties = props

  return def


bongo.on 'apiReady', ->

  definitions = { definitions: {} }

  console.log HEADER

  for name, model of bongo.models when (model.schema? and model.describeSchema?)
    try
      definitions.definitions[name] = generateDefinition model
    catch e
      console.log 'Failed on', name, e
      console.log 'Schema was:', bongo.models[name].describeSchema()
      process.exit()

  yaml = require 'js-yaml'
  console.log yaml.dump definitions

  process.exit()
