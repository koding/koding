# {exec} = require "childprocess"
fs = require "fs"
b={}

fs.readdir "../node_modules",(err,d)->
  # console.log d
  for dir in d
    do(dir)->
      fs.readFile "../node_modules/#{dir}/package.json",(err,txt)->
        unless err
          json = JSON.parse txt
          console.log "!node_modules/#{dir}/" if json?.author?.match? "Thorn"


setTimeout ->
  console.log b
,1000