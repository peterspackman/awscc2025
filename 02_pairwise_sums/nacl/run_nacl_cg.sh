#!/usr/bin/env bash
occ cg --atomic --charges=1,-1 NaCl.cif --radius=60.0 | tee nacl.stdout
