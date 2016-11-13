#!/usr/bin/env coffee

require 'coffee-cache'

fs = require 'fs'
bongo = require '../servers/lib/server/bongo'

swagger =
  swagger: "2.0"
  info:
    title: "Koding API"
    version: "0.0.2"
    description: "Koding API for integrate your application with Koding services"
    license:
      name: "Apache 2.0"
      url: "http://www.apache.org/licenses/LICENSE-2.0.html"
  tags: [
    {
      name: "system"
      description: "System endpoints for various purposes"
    },
    {
      name: "remote"
      description: "Remote API endpoints for all operations"
    }
  ]
  schemes: [
    "http"
    "https"
  ]
  parameters:
    instanceParam:
      in: "path"
      name: "id"
      description: "Mongo ID of target instance"
      required: true
      type: "string"
      default: "58261e440a7b5f3622400bed"

  paths:
    "/-/version":
      get:
        tags: [ "system" ]
        responses: "200": description: "OK"

    "/remote.api/jaccount.one":
      post:
        tags: [ "remote" ]
        consumes: [ 'application/json' ]
        parameters: [
          {
            in: "body"
            name: "body"
            description: "Pet object that needs to be added to the store"
            default: """{"profile.nickname": "guestuser"}"""
            required: true
          }
        ]
        responses:
          "200":
            description: "OK"
            schema: $ref: "#/definitions/JAccount"

    "/remote.api/jaccount.fetchEmail/{id}":
      post:
        tags: [ "remote" ]
        consumes: [ 'application/json' ]
        parameters: [
          { $ref: "#/parameters/instanceParam" }
        ]
        responses:
          "200":
            description: "OK"

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

  definitions = {}

  for name, model of bongo.models when (model.schema? and model.describeSchema?)
    try
      definitions[name] = generateDefinition model
    catch e
      console.log 'Failed on', name, e
      console.log 'Schema was:', bongo.models[name].describeSchema()
      process.exit()

  swagger.definitions = definitions
  fs.writeFileSync 'website/swagger.json', JSON.stringify swagger, ' ', 2

  process.exit()
