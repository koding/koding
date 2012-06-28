Diff = require "./lib/diff"

class DiffScriptFactory

  constructor:()->
    @src = ""

  createScript:(dest)->
    src = @src
    @src = dest
    
    if not dest? then return 'n'
    if not src.length
      return "R"+dest
    res=""
    any_change=false
    any_common=false
        
    Diff.parseDiff src,dest,(type,str)->
        switch type
          when 0 
            res+="d"+str.length+":"
            any_change=true
          when 1
            res+="i"+str.length+":"+str
            any_change=true
          when 2
            res+="k"+str.length+":"
            any_common=true
    if not any_change 
      if not any_common
        return "R"+dest     
      else 
        return "n"
    return res
  reset:()->
    @src = ""
    

module.exports = DiffScriptFactory
