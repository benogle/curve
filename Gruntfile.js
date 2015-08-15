module.exports = function(grunt) {
  grunt.initConfig({
    pkg: grunt.file.readJSON('package.json'),

    coffee: {
      build: {
        expand: true,
        cwd: 'src/',
        src: ['**/*.coffee'],
        dest: 'lib/',
        ext: '.js'
      }
    },

    browserify: {
      options: {
        browserifyOptions: {
          standalone: 'Curve'
        },
        debug: true,
      },
      production: {
        options: {
          debug: false
        },
        src: ['lib/curve.js'],
        dest: 'curve.js'
      }
    },

    uglify: {
      dist: {
        files: {
          '<%= pkg.name %>.min.js': ['<%= pkg.name %>.js']
        }
      }
    },

    watch: {
      build: {
        files: ['src/**/*.coffee'],
        tasks: ['coffee:build', 'browserify']
      },
      test: {
        files: ['src/**/*.coffee', 'spec/**/*.coffee'],
        tasks: ['shell:test']
      }
    },

    shell: {
      test: {
        command: 'node_modules/.bin/electron-jasmine ./spec',
        options: {
          stdout: true,
          stderr: true,
          failOnError: true
        }
      }
    }
  });

  grunt.loadNpmTasks('grunt-contrib-concat');
  grunt.loadNpmTasks('grunt-contrib-uglify');
  grunt.loadNpmTasks('grunt-contrib-coffee');
  grunt.loadNpmTasks('grunt-contrib-watch');
  grunt.loadNpmTasks('grunt-browserify');
  grunt.loadNpmTasks('grunt-shell');

  // grunt.registerTask('test', ['coffee', 'browserify', 'jasmine']);
  grunt.registerTask('test', ['coffee', 'browserify', 'shell:test']);
  grunt.registerTask('default', ['coffee', 'browserify', 'uglify']);
};
