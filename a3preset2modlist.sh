#!/usr/bin/env bash
xidel -se "//tr[@data-type='ModContainer']/td[@data-type='DisplayName']" "$1" | sed "s/^/@/" | sed "s/\:/\-/g"
