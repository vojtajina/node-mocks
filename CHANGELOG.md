### v0.0.15
* feat(fs): support relative paths
* fix(util.loadFile): do not override the exceptions

### v0.0.14
* http.ServerResponse: publish headerSent, getHeader, write
* http.ServerRequest: add getHeader

### v0.0.13
* Add http.ServerRequest.headers

### v0.0.12
* http.ServerResponse emit "end" event

### v0.0.11
* Added exists/existsSync to fs mocks

### v0.0.10
* Make http.ServerResponse and http.ServerRequest event emitters

### v0.0.9
* Normalize path separator

### v0.0.8
* Add fs.mkdirSync()
* Add fs.readdirSync()

### v0.0.7
* Allow injecting mocks into nested deps

### v0.0.6
* Add fs.mkdir()
* Add fs.statSync()
* Add fs.writeFile()

### v0.0.5
* Trivial implementation of chokidar
* Trivial mock for node-glob
* Improve predictableNextTick to follow pattern even for nested callbacks

### v0.0.4
Set error code on exceptions

### v0.0.3
* Correct stack trace when syntax error during loadFile
* Add missing globals to util.loadFile

### v0.0.2
* Update loadFile - allow passing globals

### v0.0.1
* Initial version, extracted from [SlimJim]

[SlimJim]: https://github.com/vojtajina/slim-jim/
