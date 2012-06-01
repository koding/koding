class Shell
  prepare: (signature, args) ->
    try
      signature.replace /(\$)([A-Za-z0-9\$_]*)/g, (str,$1,$2) ->
        arg = args[$2]
        if not arg?
          throw new Error "Shell::prepare Required argument is missing: $#{$2}"
        else
          arg
    catch error
      error
  
  exec : (command, callback) ->
    exec command, (err, stdout, stderr) ->
      unless err
        callback? command, stdout
      else
        callback? command, err

do ->
  Shell.exec = (job, signature, args) ->
    new Command(job, signature, args).exec()
  
  class Command
    constructor: (job, signature, args={}) ->
      @job = job
      @signature = signature
      @command_name = signature.split(' ')[0]
      @args = args
    exec: ->
      shell = new Shell
      cmd = @job.command = shell.prepare @signature, @args
      
      if cmd instanceof Error
        @job.finish cmd, false
      else
        proc = shell.exec cmd, (str, data) =>
          if data instanceof Error
            @job.finish data, false
          else
            if not /error/i.test data
              if 'function' is typeof @args.callback
                @args.callback(@args)
              else
                @job.finish data
            else
              @job.finish new Error("#{@command_name} stdout: "+ data), false
      proc