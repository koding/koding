
Bongo = require 'bongo'
{Relationship} = require 'jraphical'

{daisy} = Bongo

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

koding.once 'dbClientReady', ->

  JAccount   = rekuire 'account'
  JMachine   = rekuire 'computeproviders/machine'
  JWorkspace = rekuire 'workspace'


  fetchAccount = (username, callback) ->

    JAccount.one 'profile.nickname': username, callback


  createDefaultWorkspace = (machine, callback) ->

    account = workspace = null

    daisy queue = [
      ->
        process.stdout.write 'Checking default workspace'

        query =
          slug       : 'my-workspace'
          machineUId : machine.uid

        JWorkspace.one query, (err, workspace_) ->
          return console.error err  if err

          process.stdout.write ': ' + (if workspace_ then 'found' else 'not found') + "\n"

          workspace = workspace_
          queue.next()

      ->
        return queue.next()  if workspace

        username = machine.credential

        process.stdout.write "Fetching account #{username}"

        fetchAccount username, (err, account_) ->
          return console.error err  if err

          process.stdout.write ': ' + (if account_ then 'found' else 'not found') + "\n"

          account = account_
          queue.next()

      ->
        return queue.next()  if workspace
        return queue.next()  unless account

        client = connection: delegate: account

        process.stdout.write 'Creating default workspace'

        JWorkspace.createDefault client, machine.uid, (err, workspace) ->
          console.error err  if err

          process.stdout.write ": #{workspace.getId()}\n"

          queue.next()

      ->

        callback()

    ]


  fields = _id: 1, uid: 1, credential: 1, label: 1

  JMachine.someData {}, fields, {}, (err, cursor) ->

    return console.error err  if err

    iterate = ->

      cursor.nextObject (err, machine) ->

        if err
          console.error 'Cursor next object fetcher failed'
          console.error err
          process.exit 1

        if machine
          console.log 'Machine:', machine.uid
          createDefaultWorkspace machine, ->
            process.stdout.write "\n"
            iterate()
        else
          console.log 'Done'
          process.exit 0

    iterate()
