#!/bin/bash

function terminator::network::expand_url() {
  curl -sIL "$1" | grep ^Location:
}
