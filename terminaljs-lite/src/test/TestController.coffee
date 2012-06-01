Controller = require "../Controller"

console.log "creating new terminal"

options = 
  id: "vic"
  cmd: "/bin/bash"
  rows: 20
  cols: 20
  callbacks:
    data:(data)=>
      console.log ">#{data}"
    error:(error)->
      console.log "got error #{error}"


controller = new Controller

session = controller.create options

session.terminal.write "ls -la\n"

#session.terminal.setScreenSize 20,20

setTimeout ()->
  session.terminal.write("ls -la\n")  
  setTimeout ()->
    console.log "killing terminal"
    controller.kill "vic"
    console.log "all done"
  ,1000
,1000


