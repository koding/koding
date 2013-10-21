module.exports = function(grunt) {
  
  grunt.loadNpmTasks('grunt-contrib');

  // Project configuration.
  grunt.initConfig({
    pkg: '<json:package.json>',
    coffee: {
      compile: {
        files: {
          'dist/*.js': 'lib/*.coffee'
        }
      }
    }
  });
  
  // Default task.
  grunt.registerTask('default', 'coffee');
};