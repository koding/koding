module.exports =
  Database     :
    mysql      : title: 'MySQL',    package: 'mysql',       command: 'service mysql start'
    redis      : title: 'Redis',    package: 'redis',       command: ''
    mongodb    : title: 'Mongo DB', package: 'mongodb',     command: ''
    postgre    : title: 'Postgre',  package: 'postgre-sql', command: ''
    sqlite     : title: 'SQLite',   package: 'sqlite',      command: ''
  Language     :
    node       : title: 'Node.js',  package: 'node',        command: ''
    ruby       : title: 'Ruby',     package: 'ruby',        command: ''
    python     : title: 'Python',   package: 'python',      command: ''
    php        : title: 'PHP',      package: 'php',         command: ''
  'Web Server' :
    apache     : title: 'Apache',   package: 'apache',      command: ''
    nginx      : title: 'Nginx',    package: 'nginx',       command: 'nginx start'
