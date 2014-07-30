#!/usr/bin/env coffee

AWS        = require 'aws-sdk'
AWS_DEPLOY_KEY    = require("fs").readFileSync("#{__dirname}/install/keys/aws/koding-prod-deployment.pem")
AWS.config.region = 'us-east-1'
AWS.config.update accessKeyId: 'AKIAI7RHT42HWAA652LA', secretAccessKey: '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'

argv       = require('minimist')(process.argv.slice(2))
eden       = require 'node-eden'
log        = console.log
timethat   = require 'timethat'
Connection = require "ssh2"
fs         = require 'fs'
semver     = require 'semver'
{exec}     = require 'child_process'
ec2        = new AWS.EC2()
elb        = new AWS.ELB()
class Deploy

  @connect = (options,callback) ->
    {IP,username,password,retries,timeout} = options

    options.retry = yes unless options.retrying

    conn = new Connection()

    listen = (prefix, stream, callback)->
      _log = (data) -> log ("#{prefix} #{data}").replace("\n","") if data or data is not ""
      stream.on          "data", _log
      stream.stderr.on   "data", _log
      stream.on "close", callback
      # stream.on "exit", (code, signal) -> log "[#{prefix}] did exit."

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

  @createLoadBalancer = (options,callback)->
    elb.createLoadBalancer
      LoadBalancerName : options.name
      Listeners : [
        InstancePort     : 80
        LoadBalancerPort : 80
        Protocol         : "http"
        InstanceProtocol : "http"
      ]
      Subnets        : ["subnet-b47692ed"]
      SecurityGroups : ["sg-64126d01"]
    ,callback

  @createInstance = (options={}, callback) ->

    # Creates a new instance and returns a live connection.
    buildNumber  = options.buildNumber  or 1113
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
        ImageId       : "ami-1624987f" # Amazon ubuntu 14.04 "ami-1624987f" # Amazon Linux AMI x86_64 EBS
        InstanceType  : "t2.medium"
        # InstanceType  : "t2.micro"
        MinCount      : 1
        MaxCount      : 1
        SubnetId      : "subnet-b47692ed"
        KeyName       : "koding-prod-deployment"
      instanceName    : "foo#{Date.now()}"



    Deploy.createInstance options,(err,result) ->
      deployStart = new Date()
      {conn} = result

      options.buildScript = """
        echo '#{new Buffer(KONFIG.runFile).toString('base64')}' | base64 --decode > /tmp/run.sh;
        sudo bash /tmp/run.sh configure;
        sudo bash /tmp/run.sh install;
        sudo bash /opt/koding/run services;
        sudo service supervisor restart
        echo "starting services..."
        sleep 15
        echo testing webserver

        curl localhost:3000 | grep koding.com
        curl #{res.instanceData.PublicIpAddress}/ | grep koding.com

        echo testing social
        curl localhost:3030
        curl #{res.instanceData.PublicIpAddress}/social

        echo testing broker
        curl localhost:8008
        curl #{res.instanceData.PublicIpAddress}/subscribe

        echo testing kloud
        curl localhost:5500
        curl #{res.instanceData.PublicIpAddress}/kloud
        \n
        """



      conn.exec options.buildScript, (err, stream) ->
        log 4
        throw err if err
        conn.listen "[configuring #{result.instanceName}]", stream,->
          log 5
          throw err if err
          # delete result.conn
          # log result.instanceData
          log "Deployment of #{result.instanceName} took: "+timethat.calc deployStart,new Date()
          conn.end()
          callback null, result

# module.exports = Deploy


# Deploy.deployAndConfigure null,(err,res)->
#   log "#{res.instanceName} is ready."
#   log "Box is ready at mosh root@#{res.instanceData.PublicIpAddress}"


class Release

  works = ->
    elb.deregisterInstancesFromLoadBalancer
      Instances        : [{ InstanceId: 'i-dd310cf7' }]
      LoadBalancerName : "koding-prod-deployment"
    ,(err,res) ->
      log err,res


    elb.registerInstancesWithLoadBalancer
      Instances        : [{ InstanceId: 'i-dd310cf7' }]
      LoadBalancerName : "koding-prod-deployment"
    ,(err,res) ->
      log err,res


    elb.describeInstanceHealth
      Instances        : [{ InstanceId: 'i-dd310cf7' }]
      LoadBalancerName : "koding-prod-deployment"
    ,(err,res)->
      log err,res

  @fetchLoadBalancerInstances = (LoadBalancerName,callback)->
    elb.describeLoadBalancers LoadBalancerNames : [LoadBalancerName],(err,res)->
      log res.LoadBalancerDescriptions[0].Instances

    ec2.describeInstances {},(err,res)->

  fetchInstancesWithPrefix = (prefix,callback)->

    pickValueOf= (key,array) -> return val.Value if val.Key is key for val in array
    instances = []
    ec2.describeInstances {},(err,res)->
      # log err,res
      for r in res.Reservations
        a = InstanceId: r.Instances[0].InstanceId, Name: pickValueOf "Name",r.Instances[0].Tags
        b = InstanceId: r.Instances[0].InstanceId
        instances.push b if a.Name.indexOf(prefix) > -1
      # log instances
      callback null,instances

  @registerInstancesWithPrefix = (prefix, callback)->
    fetchInstancesWithPrefix prefix, (err,instances)->
      # log instances
      elb.registerInstancesWithLoadBalancer
        Instances        : instances
        LoadBalancerName : "koding-prod-deployment"
      ,callback

  @deregisterInstancesWithPrefix = (prefix, callback)->
    fetchInstancesWithPrefix prefix, (err,instances)->
      log instances
      elb.deregisterInstancesFromLoadBalancer
        Instances        : instances
        LoadBalancerName : "koding-prod-deployment"
      ,callback




release = (key)->
  Release.registerInstancesWithPrefix key,(err,res)->
    log res
    log ""
    log ""
    log "------------------------------------------------------------------------------"
    log "#{key} is now deployed and live with bazillion instances."
    log "------------------------------------------------------------------------------"

rollback = (key)->
  Release.deregisterInstancesWithPrefix key,(err,res)->
    log res
    log ""
    log ""
    log "------------------------------------------------------------------------------"
    log "#{key} is now rolled back. All instances are taken out of rotation."
    log "------------------------------------------------------------------------------"


if argv.release
  release argv.release

if argv.rollback
  rollback argv.rollback

if argv.deploy
  d = new Date()
  log "fetching latest version tag. please wait... "
  tags = exec "git fetch --tags && git tag",(a,b,c)->
    version = b.split('\n')
    version = version.slice(-2)[0]
    #log version,arguments
    version = "v1.5.0" if version is ""
    options =
      boxes       : argv.boxes          or 5
      boxtype     : argv.boxtype        or "t2.medium"
      versiontype : argv.versiontype    or "patch"  # available options major, premajor, minor, preminor, patch, prepatch, or prerelease
      target      : argv.target         or "singlebox" # prod | staging | sandbox

    options.version = argv.version or semver.inc(version,options.versiontype)
    # options.tag     = argv.tag     or semver
    options.hostname = "#{options.target}--v#{options.version.replace(/\./g,'-')}"
    #create the new tag
    log "tagging version #{options.version}"
    exec "git tag 'v#{options.version}' && git push --tags",(err,stdout,stderr)->

      if options.target is "singlebox"
        KONFIG = require("./config/main.prod.coffee")
          hostname : result.instanceName
          tag      : options.tag

        cmd = """
          echo '#{new Buffer(KONFIG.runFile).toString('base64')}' | base64 --decode > /tmp/run.sh;
          sudo bash /tmp/run.sh configure;
          sudo bash /tmp/run.sh install;
          sudo bash /opt/koding/run services;
          sudo service supervisor restart
          echo "starting services..."
          sleep 15
          echo testing webserver
          curl localhost:3000 |

          curl localhost:3030

          curl localhost:8008

          curl localhost:5500
          \n
          """


        options =
          params :
            ImageId       : "ami-864d84ee" # Amazon ubuntu 14.04 "ami-1624987f" # Amazon Linux AMI x86_64 EBS
            InstanceType  : options.boxtype
            MinCount      : 1
            MaxCount      : 1
            SubnetId      : "subnet-b47692ed"
            KeyName       : "koding-prod-deployment"
          instanceName    : "#{options.hostname}--#{eden.eve().toLowerCase()}"
          configName      : "singlebox"
          environment     : "singlebox"
          tag             : "v#{options.version}"
          buildScript     : cmd


        Deploy.deployAndConfigure options,(err,res)->
          log "#{res.instanceName} is ready."
          log "Box is ready at mosh root@#{res.instanceData.PublicIpAddress}"






