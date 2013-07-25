module.exports = function(grunt) {
  grunt.initConfig({
    pkg: grunt.file.readJSON('package.json'),

    concat: {
      dist: {
        src: ['src/**/*.coffee'],
        dest: '<%= pkg.name %>.coffee'
      }
    },

    coffee: {
      build: {
        files: {
          '<%= pkg.name %>.js': '<%= pkg.name %>.coffee',
        }
      },
      test: {
        expand: true,
        cwd: 'test/src/',
        src: ['**/*.coffee'],
        dest: 'test/lib/',
        ext: '.js'
      }
    },

    uglify: {
      options: {
        banner: '/*! CSSBelt.js - http://easelinc.github.io/cssbelt, built <%= grunt.template.today("mm-dd-yyyy") %> */\n'
      },
      dist: {
        files: {
          '<%= pkg.name %>.min.js': ['<%= pkg.name %>.js']
        }
      }
    },

    watch: {
      build: {
        files: ['src/**/*.coffee'],
        tasks: ['concat', 'coffee:build', 'jasmine']
      },
      test: {
        files: ['test/src/**/*.coffee'],
        tasks: ['coffee:test', 'jasmine']
      }
    },

    jasmine: {
      src: '<%= pkg.name %>.js',
      options: {
        specs: [
          'test/lib/nodeSpec.js',
          'test/lib/node-editorSpec.js',
          'test/lib/pathSpec.js',
          'test/lib/selection-modelSpec.js',
          'test/lib/selection-viewSpec.js'
        ],
        helpers: 'test/lib/**/*Helper.js',
        vendor: [
          'test/vendor/event-emitter.js',
          'test/vendor/svg.js',
          'test/vendor/svg.circle.js',
          'test/vendor/svg.draggable.js',
          'test/vendor/svg.import.js',
          'test/vendor/jquery-2.0.3.js',
          'test/vendor/underscore.js',
          'test/vendor/jasmine-jquery.js'
        ]
      }
    }
  });

  grunt.loadNpmTasks('grunt-contrib-concat');
  grunt.loadNpmTasks('grunt-contrib-uglify');
  grunt.loadNpmTasks('grunt-contrib-coffee');
  grunt.loadNpmTasks('grunt-contrib-watch');
  grunt.loadNpmTasks('grunt-contrib-jasmine');

  grunt.registerTask('test', ['concat', 'coffee', 'jasmine']);
  grunt.registerTask('default', ['concat', 'coffee', 'uglify']);
};
