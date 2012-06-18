module.exports =
  name              : "databases"
  pidPath           : "/var/run/node/Databases.pid"
  logFile           : "/var/log/node/Databases.log"
  port              : 4568
  pusher            :
    appId           : 22120
    key             : 'a6f121a130a44c7f5325'
    secret          : '9a2f248630abaf977547'
  apiUri            : 'https://dev-api.koding.com/1.0'
  mysql   :
    usersPath : '/Users/'
    backupDir : '/Backups/mysql'
    databases :
      mysql   :
        host     : 'koding.cfbuweg6pdxe.us-east-1.rds.amazonaws.com'
        user     : 'system'
        password : 'dlkadlakdlka'
  mongo :
    databases :
      mongodb   :
        host     : 'mongo1.beta.service.aws.koding.com'
        user     : 'admin'
        password : '22t78skhdlksaje1'
        
