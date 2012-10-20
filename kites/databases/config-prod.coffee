module.exports =
  name              : "databases"
  pidPath           : "/var/run/node/Databases.pid"
  logFile           : "/var/log/node/Databases.log"
  amqp              :
    host            : 'web0.beta.system.aws.koding.com'
    username        : 'PROD-k5it50s4676pO9O'
    password        : 'Dtxym6fRJXx4GJz'
    vhost           : '/'
  apiUri            : 'https://api.koding.com/1.0'
  mysql   :
    usersPath : '/Users/'
    backupDir : '/Backups/mysql'
    databases :
      mysql   : [
        { host     : 'mysql0.db.koding.com', user : 'system', password : 'gTW9ts2A4PXyECd69MQNAKx8v988x27cxFAu73pv' }
        { host     : 'mysql1.db.koding.com', user : 'system', password : 'gTW9ts2A4PXyECd69MQNAKx8v988x27cxFAu73pv' }
      ]
  mongo :
    databases :
      mongodb   : [
        { host     : 'mongo1.db.koding.com', user : 'admin', password : '22t78skhdlksaje1'}
        { host     : 'mongo0.db.koding.com', user : 'admin', password : '22t78skhdlksaje1'}
      ]
