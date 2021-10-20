This script replaces all client slots in a DCS mission with CJTF Blue/Red slots, allowing any livery to be used.

## Usage

* Make sure a Lua interpreter is installed on your machine

* Backup the .miz file you are going to modify

* Open the .miz file using a program capable of reading zip files (ie. 7-Zip)

* Extract the `mission` file to this folder

* Open a command prompt window and run `cjtf.lua` in Lua

* Put the generated `mission.new` file back in the .miz using the same zip tool as before

* Inside of the .miz, replace the old `mission` file with the newly-added `mission.new` file

* Run in DCS and test that the slots are working and there are no scripting errors in dcs.log
