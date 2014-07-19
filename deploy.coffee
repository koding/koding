AWS        = require 'aws-sdk'
eden       = require 'node-eden'
log        = console.log
timethat   = require 'timethat'
Connection = require "ssh2"
fs         = require 'fs'
AWS.config.region = 'us-east-1'
AWS.config.update accessKeyId: 'AKIAI7RHT42HWAA652LA', secretAccessKey: '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'

ec2 = new AWS.EC2()


class Deploy

  @connect = (options,callback) ->
    {IP,username,password,retries,timeout} = options

    options.retry = yes unless options.retrying

    conn = new Connection()

    listen = (op, stream, callback)->
      stream.on "data", (data)         -> log ("[#{op}] #{data}").replace("\n","")
      stream.on "exit", (code, signal) -> log "[#{op}] did exit."
      stream.on "close",               ->
        log "[#{op}] did close."
        callback null,"close"

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
      privateKey   : require("fs").readFileSync(__dirname+"/install/keys/aws/koding-prod-deployment.pem")
      readyTimeout : timeout


    conn.on "ready", ->
      conn.listen   = listen
      conn.sftpCopy = sftpCopy
      callback null,conn

    conn.on "error", (err) -> retry()


    retry = ->
      if options.retries > 1
        options.retries = options.retries-1
        log "retrying.. attempts left:#{options.retries}:"
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
        log """\n\n

         code:#{err.code},name:#{err.name},code:#{err.statusCode},#{err.retryable}



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
                      callback null, conn
                else
                  log "ignoring err callback", err

          ,5000

module.exports = Deploy



options =
  params :
    ImageId       : "ami-a6926dce" # Amazon ubuntu 14.04 "ami-1624987f" # Amazon Linux AMI x86_64 EBS
    InstanceType  : "c1.xlarge"
    MinCount      : 1
    MaxCount      : 1
    SubnetId      : "subnet-b47692ed"
    KeyName       : "koding-prod-deployment"
  buildNumber     : 1111
  instanceName    : null


deployStart = new Date()
Deploy.createInstance options,(err,conn) ->

  KONFIG = require("./config/main.prod.coffee")()

  fs.writeFileSync "/tmp/run.sh",KONFIG.runFile

  conn.sftp (err, sftp) ->
    log 1
    throw err if err
    sftp.fastPut "/tmp/run.sh","/tmp/run.sh",(err,res)->
      log 3
      throw err if err
      conn.exec """
          sudo bash /tmp/run.sh install;
          sudo bash /opt/koding/run services;
          # sudo bash /opt/koding/run;
      """
      , (err, stream) ->
        log 4
        throw err if err
        conn.listen "configuring", stream,->
          log 5
          throw err if err
          log "Box is ready"
          log "Deployment and configuration took: "+timethat.calc deployStart,new Date()
          conn.end()











