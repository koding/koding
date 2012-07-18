{exec} = require 'child_process'


config = 
  lvectl: '/usr/sbin/lvectl'

 

class osLimits
  
  setMemory : (options,callback)->
    # this method will set memory limit for user

    #
    # options = 
    #   username : String # username
    #   memory   : Number # new memory limit in MB

    # return error on error , null on success

    {username, memory} = options

    exec "#{config.lvectl} set $(id -u #{username}) --mem=#{memory}m --save", (err, stdout, stderr) ->
      if err?
        console.log e = "[ERROR] can't change memory limit for user #{username}: #{stderr}"
        callback e
      else
        console.log "[OK] memory limit for user #{username} has been changed to #{memory}MB"
        callback null

  setCpu : (options,callback)->
    # this method will set CPU limit for user

    #
    # options = 
    #   username : String # username
    #   cpu      : Number # in %  - 100% is max limit

    # return error on error , null on success


    {username, cpu} = options

    exec "#{config.lvectl} set $(id -u #{username}) --cpu=#{cpu} --save", (err, stdout, stderr) ->
      if err?
        console.log e = "[ERROR] can't change cpu limit for user #{username}: #{stderr}"
        callback e
      else
        console.log "[OK] cpu limit for user #{username} has been changed to #{cpu}%"
        callback null


  setWebProcs : (options,callback)->

    # this method will set CPU limit for user

    #G
    # options = 
    #   username : String # username
    #   procs      : Number # max number of processes spawned by apache

    # return error on error , null on success


    {username, procs} = options

    exec "#{config.lvectl} set $(id -u #{username}) --maxEntryProcs=#{procs} --save", (err, stdout, stderr) ->
      if err?
        console.log e = "[ERROR] can't  change procs limit for user #{username}: #{procs}"
        callback e
      else
        console.log "[OK] procs limit for user #{username} has been changed to #{procs}"
        callback null



#limit = new osLimits

#limit.setMemory username:'alekseymykhailov',memory:100,(err)->
#  if err?
#    console.log "ERR:", err

#limit.setCpu username:'alekseymykhailov',cpu:100,(err)->
#  if err?
#    console.log "ERR:", err

#limit.setWebProcs username:'alekseymykhailov',procs:100,(err)->
#  if err?
#    console.log "ERR:", err

