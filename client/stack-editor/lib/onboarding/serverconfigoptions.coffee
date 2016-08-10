module.exports =
  Database     :
    mysql      : { title: 'MySQL',      package: 'mysql-server',      command: 'service mysql start' }
    # redis      : title: 'Redis',      package: 'redis-server',      command: 'apt-get install -y python-software-properties && add-apt-repository -y ppa:rwky/redis && sudo apt-get update && sudo apt-get install -y redis-server'
    mongodb    : { title: 'Mongo DB',   package: 'mongodb',           command: '' }
    postgresql : { title: 'PostgreSQL', package: 'postgresql postgresql-contrib',    command: '' }
    sqlite     : { title: 'SQLite',     package: 'sqlite',            command: '' }
  Language     :
    node       : { title: 'Node.js',    package: 'node',              command: '' }
    ruby       : { title: 'Ruby',       package: 'ruby',              command: '' }
    python     : { title: 'Python',     package: 'python',            command: '' }
    php        : { title: 'PHP',        package: 'php5',              command: '' }
  'Web Server' :
    apache     : { title: 'Apache',     package: 'apache2',           command: '' }
    nginx      : { title: 'Nginx',      package: 'nginx',             command: 'nginx start' }
