fs = require 'fs'
http = require 'http'

create_folders = ->
	console.log '++ generating folders'
	for folder in ['src', 'vendors', 'www', 'www/js']
		console.log "++   #{folder}"
		fs.mkdirSync folder, 0o777

create_toaster_file = ->
	console.log '++ generating toaster.coffee'
	toaster_file = '''
toast 'src'
	# EXCLUDED FOLDERS (optional)
	# exclude: ['folder/to/exclude', 'another/folder/to/exclude', ... ]

	# => VENDORS (optional)
	vendors: ['vendors/jquery.min.js', 'vendors/underscore-min.js', 'vendors/backbone-min.js' ]

	# => OPTIONS (optional, default values listed)
	# bare: false
	# packaging: true
	# expose: ''
	minify: false

	# => HTTPFOLDER (optional), RELEASE / DEBUG (required)
	httpfolder: 'www'
	release: 'www/js/app.js'
	debug: 'www/js/app-debug.js'
	'''
	fs.writeFileSync 'toaster.coffee', toaster_file

download_vendor_files = (when_complete) ->
	console.log "++ downloading vendor files"
	vendor_files = [
		{ file: "underscore-min.js", host: "underscorejs.org" },
		{ file: "backbone-min.js", host: "backbonejs.org" },
		{ file: "jquery.min.js", host: "code.jquery.com"}
	]

	download_next_file = ->
		item = vendor_files.pop()
		return when_complete() if !item
		console.log "++   downloading #{item.host}/#{item.file} to vendors/#{item.file}"
		http.get {host: item.host, port: 80, path: "/#{item.file}" }, (resp) -> 
			data = ""
			resp.on 'data', (chunk) -> data += chunk
			resp.on 'end', -> fs.writeFileSync "vendors/#{item.file}", data
			download_next_file()

	download_next_file()

setup_backbone_structure = ->
	console.log "++ setting up backbone structure"
	for folder in ['app', 'app/collections', 'app/models', 'app/routers', 'app/templates', 'app/views']
		console.log "++   src/#{folder}"
		fs.mkdirSync "src/#{folder}", 0o777
	console.log "++   src/app/app.coffee"
	fs.writeFileSync "src/app/app.coffee", "# application startup code"

create_website = ->
	console.log "++ creating website"
	console.log "++   www/index.html"
	fs.writeFileSync "www/index.html", '''
<!doctype html>
<html>
	<head>
		<script type="text/javascript" src="js/app.js"></script>
	</head>

	<body>
		<h1>Hello, Robusta</h1>
	</body>
</html>
'''

create_server = ->
	console.log "++ creating server"
	console.log "++   server.coffee"
	fs.writeFileSync "server.coffee", '''
port = process.env.PORT || 3001
app = require('express').createServer()

serveUp = (res, filename) -> 
  console.log "REQUESTING: ", filename
  res.sendfile "#{__dirname}/www#{filename}"

app.get "/", (req, res) -> serveUp res, "/index.html"
app.get "/*", (req, res) -> serveUp res, req.url
   
app.listen port
console.log "Server started on #{port}"
'''

create_folders()
create_toaster_file()
download_vendor_files ->
	setup_backbone_structure()
	create_website()
	create_server()
