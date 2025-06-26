#!/usr/bin/env bash
orca led_dimer.inp | tee led_dimer.stdout
orca led_a.inp | tee led_a.stdout
orca led_b.inp | tee led_b.stdout
