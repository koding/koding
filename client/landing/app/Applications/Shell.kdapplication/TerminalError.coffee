TerminalErrno = 
  create : 
    code : 1
    name : "create"
  events_init :
    code : 2
    name: "event handlers init"
  terminal_timeout: 
    code : 3
    name: "terminal timeout"
  session_timeout:
    code : 4
    name: "session timeout" 
  connection_closed:
    code : 5
    name: "connection closed by remote peer"
  internal_error: 
    code : 6
    name: "internal error"
  

class TerminalError
  
  constructor: (error, @msg = '')->
    @errno = @lookupError error
    
  lookupError: (error)->
    if error.code? and error.name?
      errno = error
    else 
      if isNaN error
        #lookup error by name
        errno = TerminalErrno[error]
      else
        # lookup error by code
        for name,err of TerminalErrno
          if err.code == error
            errno = err 
            break
    if not errno?
      errno = 
        code: 0 
        name: "undefined"
    return errno
    
  getErrorName : ()->
    return @errno.name

  getErrorCode : ()->
    return @errno.code

  getErrorMessage: ()->
    return @msg
  
  isEqual : (error)->
    errno = @lookupError error
    return ( errno.code == @errno.code )


if typeof window is 'undefined'
  module.exports =
    "Errno": TerminalErrno 
    "Error": TerminalError
