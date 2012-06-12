module.exports =
  name              : "databases"
  pidPath           : "/var/run/node/Databases.pid"
  logFile           : "/var/log/node/Databases.log"
  port              : 4568
  mysql   :
    usersPath : '/Users/'
    backupDir : '/Backups/mysql'
    databases :
      mysql   :
        host     : 'mysql1.beta.service.aws.koding.com'
        user     : 'system'
        password : 'dlkadlakdlka'
  mongo :
    databases :
      mongodb   :
        host     : 'mongo1.beta.service.aws.koding.com'
        user     : 'admin'
        password : '22t78skhdlksaje1'
        