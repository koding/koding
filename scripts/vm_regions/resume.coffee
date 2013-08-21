#!/usr/bin/env coffee

{ argv }  = require 'optimist'

{ run }   = require './run'

{ ObjectId } = require 'mongodb'

run (db) ->

  (db.collection 'jVMs').findAndModify(

    # selector:
    {

      # # the hostnameAlias of the vm that we want to move:
      # hostnameAlias : argv.h

      # the id of the vm:
      _id: ObjectId argv.i

      # the region should be null:
      region        : null

      # hostKite is a mutex, and we should not modify this
      # document if it isn't being locked for maintenance
      hostKite      : '(maintenance)'

    }

    # sort:
    [['_id', 'asc']]

    # modifier:
    { $set: {

      # set the new region
      region    : argv.r

      # release the lock on this vm:
      hostKite  : null

    }}

    # options:
    { upsert: no }

    # callback:
    (err, doc) ->
      throw err  if err?

      if argv.d
        if doc?
          process.stdout.write "Successfully resumed #{argv.h}\n"
        else
          process.stderr.write "Couldn't resume #{argv.h}"

      process.exit()
  )
