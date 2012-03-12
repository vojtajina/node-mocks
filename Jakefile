desc('Run unit tests.');
task('test', function() {
  console.log('Running unit tests...');
  jake.exec(['jasmine-node --coffee test'], complete, {stdout: true});
});


desc('Bump minor version, update changelog, create tag, push to github.');
task('version', function () {
  var fs = require('fs');

  var packagePath = process.cwd() + '/package.json';
  var pkg = JSON.parse(fs.readFileSync(packagePath).toString());
  var versionArray = pkg.version.split('.');
  var previousVersionTag = 'v' + pkg.version;

  // bump minor version
  versionArray.push(parseInt(versionArray.pop(), 10) + 1);
  pkg.version = versionArray.join('.');

  // Update package.json with the new version-info
  fs.writeFileSync(packagePath, JSON.stringify(pkg, true, 2));

  var TEMP_FILE = '.changelog.temp';
  var message = 'Bump version to v' + pkg.version;
  jake.exec([
    // update changelog
    'echo "### v' + pkg.version + '" > ' + TEMP_FILE,
    'git log --pretty=%s ' + previousVersionTag + '..HEAD >> ' + TEMP_FILE,
    'echo "" >> ' + TEMP_FILE,
    'mvim CHANGELOG.md -c ":0r ' + TEMP_FILE + '"',
    'rm ' + TEMP_FILE,

    // commit + push to github
    'git commit package.json CHANGELOG.md -m "' + message + '"',
    'git push origin master',
    'git tag -a v' + pkg.version + ' -m "Version ' + pkg.version + '"',
    'git push --tags'
  ], function () {
    console.log(message);
    complete();
  });
});


desc('Bump version, publish to npm.');
task('publish', ['version'], function() {
  jake.exec([
    'npm publish'
  ], function() {
    console.log('Published to npm');
    complete();
  })
});


desc('Run JSLint check.');
task('jsl', function() {
  jake.exec(['jsl -conf jsl.conf'], complete, {stdout: true});
});
