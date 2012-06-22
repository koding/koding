connect = require("connect")
sharejs = require("share").server
server = connect connect.logger()

sharejs.attach server, db: type: "none"
server.listen 8000
console.log "Server running at http://localhost:8000/"