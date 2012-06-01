# this is the most retarded abstraction of fs.readFile that i've ever seen.

# fs = require "fs"
# exports = {}
# exports.readModule = (path)->
#   try
#     result = fs.readFileSync path, 'utf-8'
#   catch e
#     console.log "exception : ",e
#   if not result then throw "failed to include file [#{path}]"
#   return result
# 
# module.exports = exports