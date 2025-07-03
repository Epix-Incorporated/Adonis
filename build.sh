#!/bin/bash

echo "Updating Roblox standard library"
selene generate-roblox-std

echo "Checking for lint errors from ./Loader and ./MainModule"
selene ./Loader ./MainModule

echo "Running rojo build -o Adonis.rbxl"
rojo build -o Adonis.rbxl
