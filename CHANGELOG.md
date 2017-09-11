# CHANGELOG
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## Unreleased

## 0.0.3 - 2017-09-11
### Added
- Added a CHANGELOG.
- Added a new API for secondary view controllers to explicitly set up a 'default' detail view controller without it being explicitly pushed.

### Changed
- Fixed `TOSplitViewControllerShowTargetDidChangeNotification` notification not firing at the appropriate times.
- Fixed custom user delegate actions not saving the new view controllers properly.
