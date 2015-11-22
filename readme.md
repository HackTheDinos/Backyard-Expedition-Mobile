# Overview
Mobile app solution to the Backyard Expedition challenge at Hack the Dinos 2015

## Setup
This project uses [Carthage][carthage] to manage dependencies. These
steps should get the project building shortly:

* Clone the repo
* Install Carthage
* run `carthage bootstrap`
* open `Backyard.xcodeproj` in Xcode
* build the `Backyard` scheme

## TODO
The project is partially finished. Several components are necessary to
make this a useful, functioning application. Specifially, the collected
images and metadata need a location for submission (they are only stored
locally at the moment)

Additionally, a view of past submissions and evaluation results would
close the loop. Further enhancement of the submission flow would be to
add image processing (eg. detection of focused images or other analysis
to improve the submission quality) on the mobile client.

Pull requests welcome!

[carthage]: https://github.com/Carthage/Carthage





