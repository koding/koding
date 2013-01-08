module.exports =
  name              : "databases"
  pidPath           : "/var/run/node/Databases.pid"
  logFile           : "/var/log/node/Databases.log"
  port              : 4568
  amqp                  :
    host                : 'web0.beta.system.aws.koding.com'
    login               : 'prod-databases-kite'
    password            : 'Dtxym6fRJXx4GJz'
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
  bahadir :
    x : "d"


