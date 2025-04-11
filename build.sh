#!/bin/bash

printf "Updating Roblox standard library"
selene generate-roblox-std

printf "Checking for lint errors from ./Loader and ./MainModule"
selene ./Loader ./MainModule

printf "Running rojo build -o Adonis.rbxl"
rojo build -o Adonis.rbxl
