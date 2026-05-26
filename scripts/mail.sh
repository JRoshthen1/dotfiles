#!/bin/bash

COUNT=$(himalaya envelope list --folder INBOX -o json "not flag seen" | jq 'length')
echo "${COUNT:-0}"
