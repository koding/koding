domainName = "stage.aws.koding.com"

module.exports =
  name              : "databases"
  pidPath           : "/var/run/node/Databases.pid"
  logFile           : "/var/log/node/Databases.log"
  port              : 4568
  amqp                  :
    host                : "rabbit.#{domainName}"
    login               : 'prod-sharedhosting-kite'
    password            : 'djfjfhgh4455__5'
    heartbeat           : 10
  apiUri            : 'https://dev-api.koding.com/1.0'
  mysql             :
    usersPath       : '/Users/'
    backupDir       : '/Backups/mysql'
    databases       :
      mysql         : [
        { host : 'mysql0.db.koding.com', user : 'system', password : 'gTW9ts2A4PXyECd69MQNAKx8v988x27cxFAu73pv' }
        { host : 'mysql1.db.koding.com', user : 'system', password : 'gTW9ts2A4PXyECd69MQNAKx8v988x27cxFAu73pv' }
      ]
  mongo             :
    databases       :
      mongodb       : [
        { host : 'mongo1.db.koding.com', user : 'admin', password : '22t78skhdlksaje1'}
        { host : 'mongo0.db.koding.com', user : 'admin', password : '22t78skhdlksaje1'}
      ]


