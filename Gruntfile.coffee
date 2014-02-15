PACKAGE_ROOT = '.'

proxySnippet = require('grunt-connect-proxy/lib/utils').proxyRequest

module.exports = (grunt) ->
  pkg = grunt.file.readJSON 'package.json'
  grunt.initConfig
    coffee:
      glob_to_multiple: 
        expand: true,
        flatten: true,
        cwd: "#{PACKAGE_ROOT}/html",
        src: ['*.coffee'],
        dest: "#{PACKAGE_ROOT}/html",
        ext: '.js', 
        join: true, 

    sass:
      dist:
        files: [{
          expand: true, 
          flatten: true, 
          cwd: "#{PACKAGE_ROOT}/html", 
          src: ['*.sass'],
          dest: "#{PACKAGE_ROOT}/html",
          ext: '.css'
        }]

    hogan:
      publish:
        options:
          namespace: "Templates" 
          prettify: true 
          defaultName: (filename) ->
            console.log filename
            return filename.split('/').slice(-1)[0].split(".")[0]
        files:
          "html/template.js": ["html/*.mustache"]

    connect:
      site: {}
        # options:
        #   port: 9000,
        #   hostname: 'localhost',
        #   # keepalive: true, 
        #   livereload: true, 
        #   open: false, 
        #   middleware: (connect, options) ->
        #     return [proxySnippet]
        #   ,

      # server:
      #   proxies: [{
      #     context: '/',
      #     host: 'localhost',
      #     port: 6543,
      #     https: false,
      #     changeOrigin: false,
      #   }]

    watch:
      options:
        livereload: true
      files: [
        "#{PACKAGE_ROOT}/**/*.coffee", 
        "#{PACKAGE_ROOT}/**/*.sass", 
        "#{PACKAGE_ROOT}/**/*.mustache", 
        "#{PACKAGE_ROOT}/**/*.html", 
      ]
      tasks: [
        'coffee',
        'sass',
        'hogan',
      ]
  
  for taskName of pkg.devDependencies when taskName.substring(0, 6) is 'grunt-'
    grunt.loadNpmTasks taskName

  grunt.registerTask 'default', [
    'coffee', 
    'sass', 
    'hogan', 
    # 'configureProxies:server', 
    'connect', 
    'watch'
  ]
