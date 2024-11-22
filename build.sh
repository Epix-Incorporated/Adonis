#!/bin/bash

printf "Checking for lint errors from ./Loader and ./MainModule"
selene ./Loader ./MainModule

printf "Running rojo build -o Adonis.rbxm"
rojo build -o Adonis.rbxm
