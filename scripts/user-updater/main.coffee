
Bongo     = require 'bongo'

{ join: joinPath } = require 'path'

argv      = require('minimist') process.argv
KONFIG    = require('koding-config-manager').load("main.#{argv.c}")

mongo     = "mongodb://#{ KONFIG.mongo }"
modelPath = '../../workers/social/lib/social/models'
rekuire   = (p)-> require joinPath modelPath, p

koding = new Bongo
  root   : __dirname
  mongo  : mongo
  models : modelPath

console.log "Trying to connect #{mongo} ..."

koding.once 'dbClientReady', ->

  JAccount     = rekuire 'account.coffee'
  JDomainAlias = rekuire 'domainalias.coffee'

  index  = 0
  dindex = 0

  JAccount.count {type:'registered'}, (err, total)->
    return console.warn err  if err?

    JAccount.each {type:'registered'}, {}, (err, account)->
      return console.warn err  if err?
      return  unless account?

      index++
      console.log "Working on #{index}. user"  if index % 10 is 0
      JDomainAlias.ensureTopDomainExistence account, null, (err)->
        console.warn err  if err?
        dindex++
        if dindex is total
          console.log "#{index} users updated."
          console.log "Have a nice day!"
          process.exit 0
