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
      },
      test: {
        expand: true,
        cwd: 'test/src/',
        src: ['**/*.coffee'],
        dest: 'test/lib/',
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
          'test/lib/object-editorSpec.js',
          'test/lib/pathSpec.js',
          'test/lib/path-editorSpec.js',
          'test/lib/path-parserSpec.js',
          'test/lib/selection-modelSpec.js',
          'test/lib/selection-viewSpec.js',
          'test/lib/subpathSpec.js',
          'test/lib/svg-documentSpec.js',
          'test/lib/transformSpec.js'
        ],
        helpers: 'test/lib/**/*Helper.js',
        vendor: [
          'vendor/event-emitter.js',
          'vendor/svg.js',
          'vendor/jquery-2.0.3.js',
          'vendor/underscore.js',
          'vendor/jasmine-jquery.js'
        ]
      }
    }
  });

  grunt.loadNpmTasks('grunt-contrib-concat');
  grunt.loadNpmTasks('grunt-contrib-uglify');
  grunt.loadNpmTasks('grunt-contrib-coffee');
  grunt.loadNpmTasks('grunt-contrib-watch');
  grunt.loadNpmTasks('grunt-contrib-jasmine');
  grunt.loadNpmTasks('grunt-browserify');

  grunt.registerTask('test', ['coffee', 'browserify', 'jasmine']);
  grunt.registerTask('default', ['coffee', 'browserify', 'uglify']);
};
