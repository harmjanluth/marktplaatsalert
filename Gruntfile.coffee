module.exports = (grunt) ->

	# Project configuration.
	grunt.initConfig
		pkg: grunt.file.readJSON 'package.json'
		coffee:
			compile:
				options:
					join: true
					bare: true
				files:
					'src/js/main.js' : 'src/coffeescript/*.coffee'
		sass:
			compile:
				files:
					'src/css/main.css' : 'src/sass/main.sass'
		watch:
			app:
				files: [ '**/*.coffee', '**/*.sass' ]
				tasks: [ 'coffee', 'sass' ]
		concat:  
			options:
				separator: ';'
			js:
				src: [
						'src/js/vendor/moment.min.js',
						'src/js/vendor/moment.lang.nl.js',
						'src/js/vendor/underscore.js'
						'src/js/vendor/serialize-0.2.min.js'
						'src/js/vendor/fastclick.js'
						'src/js/main.js'
					 ]
				dest: 'src/js/<%= pkg.name %>.js'
			css:
				src: ['src/css/fontello.css', 'src/css/animation.css', 'src/css/main.css']
				dest: 'src/css/staatkudos.css'
		uglify:
			options:
				banner: '/*! <%= pkg.name %> <%= grunt.template.today("dd-mm-yyyy") %> */\n'
				flatten:true
				expand:true
			build:
				files:
					'build/js/<%= pkg.name %>.min.js': ['<%= concat.js.dest %>']
		cssmin:
			minify:
				expand:true
				cwd: 'src/css'
				src: 'staatkudos.css'
				dest: 'build/css/'
				ext: '.min.css'
		copy:
			main:
				expand: true
				cwd: 'src'
				dest: 'build'
				src: [ 'index.html', 'img/**/*', 'fonts/**/*', 'favicon.ico', 'js/vendor/placeholders.min.js', 'js/vendor/html5shiv.js', 'snapshot/**/*', '.htaccess' ]
		clean:
			cwd: ''
			options:
				force: true
			build:
				src : [ 'build' ]

		processhtml :
			dist:
				options:
					process: false
				files: 'build/index.html' : [ 'build/index.html' ]

		ftp_push : 
			staatkudos:
				options:
					authKey: 'production'
					host: 'ftp.imice.nl'
					dest: '/webroot/'
					port: 21
				files: [ 
					expand: true
					cwd: 'build'
					src: ['**/*']
				]
		htmlSnapshot :
			all:
				options:
					snapshotPath: 'src/snapshot/'
					fileNamePrefix: 'index'
					removeScripts: true
					removeLinkTags: true
					bodyAttr: 'data-prerendered'
					sitePath: 'http://localhost/root/staatkudos/src/'
					msWaitForPages: 1000
					urls: ['']

	# These plugins provide necessary tasks.
	grunt.loadNpmTasks 'grunt-contrib-coffee'
	grunt.loadNpmTasks 'grunt-contrib-copy'
	grunt.loadNpmTasks 'grunt-contrib-clean'
	grunt.loadNpmTasks 'grunt-contrib-sass'
	grunt.loadNpmTasks 'grunt-contrib-watch'
	grunt.loadNpmTasks 'grunt-contrib-clean'
	grunt.loadNpmTasks 'grunt-contrib-concat'
	grunt.loadNpmTasks 'grunt-contrib-uglify'
	grunt.loadNpmTasks 'grunt-contrib-cssmin'
	grunt.loadNpmTasks 'grunt-processhtml'
	grunt.loadNpmTasks 'grunt-ftp-push'
	grunt.loadNpmTasks 'grunt-html-snapshot'
	
	# Default task.
	grunt.registerTask 'default', [ 'watch' ]
	grunt.registerTask 'build', [ 'coffee', 'sass', 'concat', 'uglify', 'cssmin', 'htmlSnapshot', 'copy', 'processhtml' ]
	grunt.registerTask 'deploy', [ 'build', 'ftp_push' ]
	grunt.registerTask 'clean', [ 'clean:build' ]