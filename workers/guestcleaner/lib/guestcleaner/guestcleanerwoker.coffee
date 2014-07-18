jraphical = require 'jraphical'
{Base, race, daisy} = require "bongo"
{CronJob} = require 'cron'
_ = require "underscore"

module.exports = class GuestCleanerWorker
  {Relationship} = jraphical
  constructor: (@bongo, @options = {}) ->

  whitlistedModels = ["JSession", "JUser", "JVM", "JDomain", "JAppStorage", "JName"]

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
      unless modelConstructor
        console.log "No data found for guest, model name: ", modelName
        return callback null
      modelConstructor.remove {_id: $in : ids}, (err)->
        if err then callback err
        fin()
    , -> callback null

    for modelName, ids of relData
      ids = _.uniq ids
      deleteEntry {ids: ids, modelName: modelName}

  clean:=>
    {JAccount, JSession, JName} = @bongo.models

    usageLimitInMinutes = @options.usageLimitInMinutes or 60
    filterDate = new Date(Date.now()-(1000*60*usageLimitInMinutes))

    selector = {
      "meta.createdAt" : {$lte : filterDate},
      type : "unregistered",
      status : {$ne : 'tobedeleted'}
    }

    options = {limit:250}

    JAccount.some selector, options, (err, accounts)=>
      return console.error err  if err
      return  if accounts?.length < 1

      accountIds = _.map accounts, (account)-> return account._id

      JAccount.update {_id: $in: accountIds}, {$set: status: 'tobedeleted'}, {multi: yes}, (err)=>
        if err then console.error err

        accounts.forEach (account) =>
          queue = [
            ->
              console.log "Removing " + account.profile.nickname
              queue.next()
            ->
              # delete user cookie
              # instead of sending account as content, just send nickname
              # it causes FRAME_ERROR frame_too_large error
              account.sendNotification "GuestTimePeriodHasEnded", username:account.profile.nickname
              queue.next()
            =>
               # collect relationships and to be deletedData
              relationshipSelector = $or: [
                {targetId: account.getId()}
                {sourceId: account.getId()}
              ]
              Relationship.some relationshipSelector, {}, (err, relationships)=>
                if err then console.error err
                @collectDataAndRelationships relationships, (toBeDeletedData, toBeDeletedRelationshipIds)=>
                  @toBeDeletedData = toBeDeletedData
                  @toBeDeletedRelationshipIds = toBeDeletedRelationshipIds
                  queue.next()
            =>
              #if we dont have toBeDeletedRelationship do not continue
              unless @toBeDeletedRelationshipIds.length > 0
                queue.next()
              @deleteData @toBeDeletedData, (err)->
                if err then console.error err
                queue.next()
            =>
              {Relationship} = jraphical
              unless @toBeDeletedRelationshipIds.length > 0 then queue.next()
              Relationship.remove {_id : $in : @toBeDeletedRelationshipIds}, (err)->
                if err then console.error err
                queue.next()
            ->
              #JSession doesnt have any relationship to JAccount
              guestId = account.profile.nickname.split("-")[1]
              # one user can have multiple sessions but, guest account can only has one session!
              console.log "GuestCleanerWorker.clean JSession#remove", {guestId}
              JSession.remove {guestId:guestId},(err)->
                if err then console.error err
                queue.next()
            =>
              #If we don't delete JNames, we eventually have millions of them.
              JName.remove {name : account.profile.nickname},(err)->
                if err then console.error err
                queue.next()
            ->
              #Delete JAccount itself
              account.remove (err)->
                if err then console.error err
                queue.next()
            ->
              console.log "Removed " + account.profile.nickname
              queue.next()
          ]
          daisy queue

  init:->
    guestCleanerCron = new CronJob @options.cronSchedule, @clean
    guestCleanerCron.start()
