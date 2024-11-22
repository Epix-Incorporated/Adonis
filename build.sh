#!/bin/bash

# Check for lint errors in Loader and MainModule
selene ./Loader ./MainModule

# Build project file to binary model file
rojo build -o Adonis.rbxm
