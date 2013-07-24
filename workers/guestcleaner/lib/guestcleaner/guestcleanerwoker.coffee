jraphical = require 'jraphical'
{Base, race, daisy} = require "bongo"
{CronJob} = require 'cron'
_ = require "underscore"

module.exports = class GuestCleanerWorker
  {Relationship} = jraphical
  constructor: (@bongo, @options = {}) ->

  whitlistedModels = ["JSession", "JUser", "JVM", "JDomain", "JAppStorage", "JLimit"]

  collectDataAndRelationships:(relationships, callback)->
    toBeDeletedData = {}
    toBeDeletedRelationshipIds = []
    for relationship in relationships
      toBeDeleted = false
      if relationship.sourceName in whitlistedModels
        unless toBeDeletedData[relationship.sourceName] then toBeDeletedData[relationship.sourceName] = []
        toBeDeletedData[relationship.sourceName].push relationship.sourceId
        toBeDeleted = true
      if relationship.targetName in whitlistedModels
        unless toBeDeletedData[relationship.targetName] then toBeDeletedData[relationship.targetName] = []
        toBeDeletedData[relationship.targetName].push relationship.targetId
        toBeDeleted = true
      #get relationnship id to delete after deleting original data
      #this is here because we are not deleting relationships of data which are deleted by static remove method.
      toBeDeletedRelationshipIds.push relationship._id if toBeDeleted
    callback toBeDeletedData, toBeDeletedRelationshipIds

  deleteData:(relData, callback)->
    deleteEntry = race (i, data, fin)->
      {ids, modelName} = data
      modelConstructor = Base.constructors[modelName]
      modelConstructor.remove {_id: $in : ids}, (err)->
        if err then callback err
        fin()
    , -> callback null

    for modelName, ids of relData
      ids = _.uniq ids
      deleteEntry {ids: ids, modelName: modelName}

  clean:=>
    console.log "Cleaning started"
    {JAccount, JSession} = @bongo.models

    usageLimitInMinutes = @options.usageLimitInMinutes or 60
    filterDate = new Date(Date.now()-(1000*60*usageLimitInMinutes))

    selector =
      "meta.createdAt" : $lte : filterDate
      type : "unregistered"

    JAccount.each selector, {}, (err, account)=>
      if err then return console.error err
      unless account then return console.log "Empty result"

      # delete user cookie
      account.sendNotification "GuestTimePeriodHasEnded", account

      daisy queue = [
        =>
           # collect relationships and to be deletedData
          console.log "Collect related data"
          relationshipSelector = $or: [
            {targetId: account.getId()}
            {sourceId: account.getId()}
          ]
          Relationship.some relationshipSelector, {}, (err, relationships)=>
            if err then return console.error err
            @collectDataAndRelationships relationships, (toBeDeletedData, toBeDeletedRelationshipIds)=>
              @toBeDeletedData = toBeDeletedData
              @toBeDeletedRelationshipIds = toBeDeletedRelationshipIds
              queue.next()
        =>
          console.log "Deleting relationships started"
          #if we dont have toBeDeletedRelationship do not continue
          unless @toBeDeletedRelationshipIds.length > 0
            console.log "No relationship found to be deleted!"
            queue.next()
          console.log "Deleting Data"
          @deleteData @toBeDeletedData, (err)->
            if err then return console.error err
            console.log "Deleting Data Completed"
            queue.next()
        =>
          console.log "Deleting Relationships"
          unless @toBeDeletedRelationshipIds.length > 0 then queue.next()
          Relationship.remove {_id : $in : @toBeDeletedRelationshipIds}, (err)->
            if err then return console.error err
            console.log "Deleting Relationships Completed"
            queue.next()
        ->
          #JSession doesnt have any relationship to JAccount
          console.log "Removing JSession"
          guestId = account.profile.nickname.split("-")[1]
          # one user can have multiple sessions but, guest account can only has one session!
          JSession.remove {guestId:guestId},(err)->
            if err then return console.error err
            console.log "JSession is deleted"
            queue.next()
        ->
          #Delete JAccount itself
          console.log "Deleting JAccount itself"
          account.remove (err)->
            if err then return console.error err
            console.log "JAccount is removed"
            queue.next()
      ]
      console.log "Removing " + account.profile.nickname



  init:->
    guestCleanerCron = new CronJob @options.cronSchedule, @clean
    guestCleanerCron.start()
