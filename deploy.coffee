#!/usr/bin/env coffee

AWS        = require 'aws-sdk'
AWS_DEPLOY_KEY    = require("fs").readFileSync("#{__dirname}/install/keys/aws/koding-prod-deployment.pem")
AWS.config.region = 'us-east-1'
AWS.config.update accessKeyId: 'AKIAI7RHT42HWAA652LA', secretAccessKey: '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'

eden       = require 'node-eden'
log        = console.log
timethat   = require 'timethat'
Connection = require "ssh2"
fs         = require 'fs'
ec2        = new AWS.EC2()
elb        = new AWS.ELB()
class Deploy

  @connect = (options,callback) ->
    {IP,username,password,retries,timeout} = options

    options.retry = yes unless options.retrying

    conn = new Connection()

    listen = (op, stream, callback)->
      _log = log ("[#{op}] #{data}").replace("\n","")
      stream.on        "data", (data), _log
      stream.stderr.on "data", (data), _log
      stream.on "exit", (code, signal) -> log "[#{op}] did exit."
      stream.on "close",               -> callback null,"close"

    sftpCopy = (options, callback)->
      copyCount = 1
      results = []
      options.conn.sftp (err, sftp) ->
        for file,nr in options.files
          do (file)->
            sftp.fastPut file.src,file.trg,(err,res)->
              if err
                log "couldn't copy:",file
                throw err
              log file.src+" is copied to "+file.trg
              if copyCount is options.files.length then callback null,"done"
              copyCount++

    conn.connect
      host         : IP
      port         : 22
      username     : username
      privateKey   : AWS_DEPLOY_KEY
      readyTimeout : timeout


    conn.on "ready", ->
      conn.listen   = listen
      conn.sftpCopy = sftpCopy
      callback null,conn

    conn.on "error", (err) -> retry()


    retry = ->
      if options.retries > 1
        options.retries = options.retries-1
        log "connecting to instance.. attempts left:#{options.retries}"
        setTimeout (-> Deploy.connect options, callback),timeout
      else
        log "not retrying anymore.", options.retries
        callback "error connecting."

  @createInstance = (options={}, callback) ->

    # Creates a new instance and returns a live connection.
    buildNumber  = options.buildNumber  or 1111
    instanceName = options.instanceName or "prod-#{buildNumber}-#{eden.eve().toLowerCase()}"

    params = options.params or
      ImageId       : "ami-a6926dce" # Amazon ubuntu 14.04 "ami-1624987f" # Amazon Linux AMI x86_64 EBS
      InstanceType  : "t2.micro"
      MinCount      : 1
      MaxCount      : 1
      SubnetId      : "subnet-b47692ed"
      KeyName       : "koding-prod-deployment"

    iamcalledonce = 0

    start = new Date()

    ec2.runInstances params, (err, data) ->
      iamcalledonce++
      if iamcalledonce > 1 then return log "i am called #{iamcalledonce} times"
      if err
        # log "\n\nCould not create instance ---->", err
        log """code:#{err.code},name:#{err.name},code:#{err.statusCode},#{err.retryable}
         ---
         [ERROR] #{err.message}
        \n\n
        """
        return
      else
        instanceId = data.Instances[0].InstanceId
        log "-----> Created instance", instanceId

        # Add tags to the instance
        params =
          Resources: [instanceId]
          Tags: [
            Key   : "Name"
            Value : instanceName
          ]

        ec2.createTags params, (err) ->
          log "-----> Tagged with #{instanceName}", (if err then "failure" else "success")

          params =
            InstanceIds : [instanceId]

          states =
            initialState  : null
            instanceState : null
            reachability  : null
          __ = setInterval ->

            unless states.initialState is "running" or states.instanceState is "running"

              ec2.describeInstanceStatus params,(err,data)->
                if err then log err
                else
                  states.instanceState = data?.InstanceStatuses?[0]?.InstanceState?.Name
                  states.reachability  = data?.InstanceStatuses?[0]?.InstanceStatus?.Details?[0]?.Status

              ec2.describeInstances params,(err,data)->
                if err then log err
                else
                  states.initialState = data?.Reservations?[0]?.Instances?[0]?.State?.Name
                  states.final        = data?.Reservations?[0]?.Instances?[0]
            else
              log "instance is now running with IP:", IP = states.final.PublicIpAddress
              clearInterval __

              Deploy.connect IP: IP, username: "ubuntu", retries: 30, timeout: 5000, (err,conn)->
                unless err
                  log "creating #{instanceName} took "+ timethat.calc start,new Date()
                  conn.exec "uptime;",(err, stream)->

                    return log err  if err
                    conn.listen "-->", stream,->
                      log "connection established... preparing the box."
                      conn.final = states.final

                      res =
                        conn : conn
                        instanceData : states.final
                        instanceName : instanceName
                        buildOptions : options

                      callback null, res
                else
                  log "ignoring err callback", err

          ,5000

  @deployAndConfigure = (options,callback)->

    options = options or
      params :
        ImageId       : "ami-a6926dce" # Amazon ubuntu 14.04 "ami-1624987f" # Amazon Linux AMI x86_64 EBS
        InstanceType  : "t2.medium"
        MinCount      : 1
        MaxCount      : 1
        SubnetId      : "subnet-b47692ed"
        KeyName       : "koding-prod-deployment"
      buildNumber     : 1111
      instanceName    : null


    deployStart = new Date()
    Deploy.createInstance options,(err,result) ->

      {conn} = result

      KONFIG = require("./config/main.prod.coffee")
        hostname : result.instanceName

      cmd = """
        echo '#{new Buffer(KONFIG.runFile).toString('base64')}' | base64 --decode > /tmp/run.sh;
        sudo bash /tmp/run.sh install;
        sudo bash /opt/koding/run services;
        sudo service supervisor restart
        \n
        """
      conn.exec cmd, (err, stream) ->
        log 4
        throw err if err
        conn.listen "configuring", stream,->
          log 5
          throw err if err
          #delete result.conn
          log result.instanceData
          log "Deployment and configuration took: "+timethat.calc deployStart,new Date()
          conn.end()
          callback null, result

module.exports = Deploy

Deploy.deployAndConfigure null,(err,res)->
  log "Box is ready at mosh root@#{res.instanceData.PublicIpAddress}"


# class Release





