#!/bin/bash

function terminator::user::is_root() {
  (( EUID == 0 )) || [[ "$(id -u)" -eq 0 ]]
}
