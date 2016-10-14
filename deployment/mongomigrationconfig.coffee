fs = require 'fs'
module.exports.create = (KONFIG)->

  conn = { "conn": { "connectionString": "mongodb://#{KONFIG.mongo}" } }
  fileName = "./deployment/generated_files/mongomigration.json"
  fs.writeFileSync fileName, JSON.stringify conn
