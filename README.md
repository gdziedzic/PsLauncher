# PsLauncher

PsLauncher is a script that helps you launch *things* quickly. A *thing* can be a local or remote directory, a web link or an app. See the `pslauncher.json` file for examples. 

# How to use it?

`. .\pslauncher.ps1` load the script

`Launch "users"` list results matching "users" string

`Launch "users" -r 4` run the 4th result (alternatively `Launch "users" 4`)

`Launch "users" -c 3` copy 3rd result to the clipboard

Define your quick launch list elements in the `pslauncher.json` file.