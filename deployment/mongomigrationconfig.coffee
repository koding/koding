#!/usr/bin/env coffee

fs = require 'fs'

module.exports.create = create = (KONFIG) ->

  connectionString = "mongodb://#{KONFIG.mongo}"
  conn = { connectionString }
  fileName = './deployment/generated_files/mongomigration.json'
  fs.writeFileSync fileName, JSON.stringify { conn }

if require.main is module
  mongo = process.env.KONFIG_MONGO
  create { mongo }
