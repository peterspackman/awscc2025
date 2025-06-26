#!/usr/bin/env bash
orca A.inp| tee A.stdout 
orca B.inp| tee B.stdout 
orca AB.inp | tee AB.stdout
