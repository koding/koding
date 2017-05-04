#!/usr/bin/env coffee
# coffeelint: disable=cyclomatic_complexity

require 'coffee-cache'

fs     = require 'fs'
path   = require 'path'
bongo  = require '../servers/lib/server/bongo'
docGen = require './docgen'
{ expect } = require 'chai'

swagger =
  swagger: '2.0'
  basePath: '/remote.api'
  host: 'koding.com'
  info:
    title: 'Koding API'
    version: '0.0.3'
    description: 'Koding API for integrating your application with Koding services'
    license:
      name: 'Apache 2.0'
      url: 'http://www.apache.org/licenses/LICENSE-2.0.html'

  securityDefinitions:
    Bearer:
      type: 'apiKey'
      name: 'Authorization'
      in: 'header'

  tags: [
    {
      name: 'system'
      description: 'System endpoints for various purposes'
    }
  ]

  definitions:
    Error:
      type: 'object'
      properties:
        message:
          type: 'string'
          description: 'Error description'
          example: 'Something went wrong'
        name:
          type: 'string'
          description: 'Name of the error'
          example: 'KodingError'
    DefaultSelector:
      type: 'object'
    DefaultResponse:
      type: 'object'
      properties:
        ok:
          type: 'boolean'
          description: 'If the request processed by endpoint'
          example: true
        error:
          type: 'object'
          description: 'Error description'
          example:
            message: 'Something went wrong'
            name: 'SomethingWentWrong'
        data:
          type: 'object'
          description: 'Result of the operation'
          example: 'Hello World'
    UnauthorizedRequest:
      type: 'object'
      properties:
        status:
          type: 'integer'
          description: 'HTTP Error Code'
          example: 401
        message:
          type: 'string'
          description: 'Error description'
          example: 'The request is unauthorized, an api token is required.'
        code:
          type: 'string'
          description: 'Error Code'
          example: 'UnauthorizedRequest'

  parameters:
    instanceParam:
      in: 'path'
      name: 'id'
      description: 'Mongo ID of target instance'
      required: true
      type: 'string'
    bodyParam:
      in: 'body'
      name: 'body'
      schema:
        $ref: '#/definitions/DefaultSelector'
      required: true
      description: 'body of the request'

  paths: {}

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

  if prop.default? and prop.default?.type is 'default'
    delete prop.default

  if prop.required
    def.required ?= []
    def.required.push field
    delete prop.required

  return prop


generateDefinition = (model) ->

  schema = model.describeSchema()
  def    = { type: 'object' }
  props  = { _id: { type: 'string' } }

  for field, prop of schema
    continue if field is 'default' and prop.type is 'default'

    if 'type' not in Object.keys prop
      props[field] = { properties: {} }
      for subfield, subprop of prop
        continue if subfield is 'default' and subprop.type is 'default'
        props[field].properties[subfield] = getProps subprop, def, field
    else
      props[field] = getProps prop, def, field

  def.properties = props

  return def


generateMethodPaths = (model, definitions, paths, docs) ->

  name = model.name
  methods = model.getSharedMethods()

  schema = if definitions[name]
  then { allOf: [ { $ref: "#/definitions/#{name}" }, { $ref: '#/definitions/DefaultResponse' } ] }
  else { $ref: '#/definitions/DefaultResponse' }

  # currently swagger-codegen does not support multiple response types
  # which causes to generate unexpected client api. So, for now we're
  # only providing the DefaultResponse schema ~ GG
  # ref: https://github.com/swagger-api/swagger-codegen/issues/358
  schema = { $ref: '#/definitions/DefaultResponse' }

  for method, signatures of methods.statik

    response      =
      description : 'Request processed successfully'
      schema      :
        $ref      : '#/definitions/DefaultResponse'

    if hasParams = signatures.length > 1 or signatures[0].split(',').length > 1
      parameters = [{ $ref: '#/parameters/bodyParam' }]
      examples = docs[name]['static'][method]?.examples ? []
      if (returns = docs[name]['static'][method]?.returns) and Object.keys(returns).length
        response =
          description: returns.description ? 'Request processed successfully'
          schema: { $ref: "#/definitions/#{returns.type}" }

      for example in examples
        if example.title is 'api'
          parameters = [
            {
              in: 'body'
              name: 'body'
              schema: example.schema
              required: true
              description: 'body of the request'
            }
          ]
        else if example.title is 'return'
          response.schema =
            type: 'object'
            properties:
              ok:
                type: 'boolean'
                description: 'If the request processed by endpoint'
                example: true
              error:
                type: 'object'
                description: 'Error description'
                example:
                  message: 'Something went wrong'
                  name: 'SomethingWentWrong'
              data: example.schema

    else
      parameters = null

    paths["/#{name}.#{method}"] =
      post:
        tags: [ name ]
        consumes: [ 'application/json' ]
        operationId: "#{method}"
        parameters: parameters ? []
        security: [ { Bearer: [] } ]
        description: docs[name]['static'][method]?.description ? ''
        responses:
          '200':
            description: response.description
            schema: response.schema
          '401':
            description: 'Unauthorized request'
            schema:
              $ref: '#/definitions/UnauthorizedRequest'


  for method, signatures of methods.instance

    hasCustomParams = no
    parameters = [{ $ref: '#/parameters/instanceParam' }]
    response = { description: 'OK', schema }
    if returns = docs[name]['instance'][method]?.returns
      if Object.keys(returns).length and swagger.definitions[returns.type]
        response =
          description: returns.description
          schema: { $ref: "#/definitions/#{returns.type}" }

    if hasParams = signatures.length > 1 or signatures[0].split(',').length > 1
      examples = docs[name]['instance'][method]?.examples ? []
      for example in examples
        if example.title is 'api'
          parameters.push {
            in: 'body'
            name: 'body'
            schema: example.schema
            required: true
            description: 'body of the request'
          }
          hasCustomParams = yes
        else if example.title is 'return'
          response.schema = example.schema

    unless hasCustomParams
      parameters.push { $ref: '#/parameters/bodyParam' }

    paths["/#{name}.#{method}/{id}"] =
      post:
        tags: [ name ]
        operationId: "#{method}"
        security: [ { Bearer: [] } ]
        consumes: [ 'application/json' ]
        description: docs[name]['instance'][method]?.description ? ''
        parameters: parameters
        responses:
          '200':
            description: response.description
            schema: response.schema
          '401':
            description: 'Unauthorized request'
            schema:
              $ref: '#/definitions/UnauthorizedRequest'


module.exports = generateApi = (callback) ->

  bongo.on 'apiReady', ->

    definitions = swagger.definitions
    paths       = swagger.paths
    tags        = swagger.tags
    docs        = docGen bongo.modelPaths[0], bongo.modelFiles

    if docs.errors.length > 0
      return callback
        message: 'Docs has errors!'
        details: { error: doc.errors }
    else
      docs = docs.doc

    for name, model of bongo.models

      swagger.tags.push {
        description: docs[name].description
        name
      }

      try
        if model.schema? and model.describeSchema?
          definitions[name] = generateDefinition model
      catch error
        schema = bongo.models[name].describeSchema()
        return callback
          message: 'Failed while building definitions!'
          details: { name, error, schema }

      try
        generateMethodPaths model, definitions, paths, docs
      catch error
        methods = bongo.models[name].getSharedMethods()
        return callback
          message: 'Failed while building methods!'
          details: { name, error, methods }

        process.exit()

    swagger.paths = paths
    swagger.definitions = definitions

    callback null, swagger


unless module.parent

  swaggerFilePath = path.resolve path.join __dirname, '../website/swagger.json'

  generateApi (err, swagger) ->

    if err
      console.error err
      process.exit 1

    swaggerInJson = JSON.stringify swagger, ' ', 2

    if process.argv[2] is '--check'
      try
        oldDataInJson = (fs.readFileSync swaggerFilePath).toString()
        oldData = JSON.parse oldDataInJson
        expect(oldData).to.deep.equal JSON.parse swaggerInJson
        console.log 'Swagger.json is up-to-date'
      catch e
        console.error '''
          Swagger.json is outdated. Please run following commands to update it;

            ./run exec scripts/api-generator.coffee

          and commit updated swagger.json file to current branch

        '''
        process.exit 1

    else
      fs.writeFileSync swaggerFilePath, swaggerInJson
      console.log 'Swagger.json updated succesfully!'

    process.exit()
