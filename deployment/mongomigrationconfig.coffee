fs = require 'fs'
module.exports.create = (KONFIG)->

  connectionString = "mongodb://#{KONFIG.mongo}"
  conn = { connectionString }
  fileName = "./deployment/generated_files/mongomigration.json"
  fs.writeFileSync fileName, JSON.stringify { conn }
