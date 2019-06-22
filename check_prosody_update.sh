#!/bin/bash
( apt update -qq && apt list --upgradable ) 2> /dev/null | grep prosody

