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

      # this is the region that we're migrating from:
      region        : argv.r

      # hostKite is a mutex, and we should not modify this
      # document if it isn't null
      hostKite      : null

    }

    # sort:
    [['_id', 'asc']]

    # modifier:
    { $set: {

      # we should set the hostKite mutex to maintenance mode
      # so that this VM cannot be mounted elsewhere while we
      # are migrating it (that could result in data corruption.)
      hostKite  : '(maintenance)'

      # set the region to null (we're in between regions now.)
      region    : null

    }}

    # options:
    { upsert: no }

    # callback:
    (err, doc) ->
      throw err  if err?

      if argv.d
        if doc?
          process.stdout.write "Successfully suspended #{argv.h}\n"
        else
          process.stderr.write "Couldn't suspend #{argv.h}"

      process.exit()
  )
