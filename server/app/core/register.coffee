class Register
  constructor:->
    return new Register unless @ instanceof Register
    
    signatures = {}
    @__defineGetter__ 'signatures', -> Object.keys signatures
  
    @sign = (ids)->
      unless _.isArray ids
        onlyOne = yes
        ids = [ids]
    
      results = []
    
      for id in ids
        results.push not signatures[id]?
        signatures[id] = yes
    
      if onlyOne then results[0] else results