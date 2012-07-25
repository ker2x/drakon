#!/usr/bin/env bash

../drakon_gen.tcl -in ../generators/python.drn
../drakon_gen.tcl -in ../generators/cycle_body.drn
../drakon_gen.tcl -in ../generators/node_sorter.drn
../drakon_gen.tcl -in ../generators/c.drn
../drakon_gen.tcl -in ../generators/cpp.drn
../drakon_gen.tcl -in ../generators/nogoto.drn
../drakon_gen.tcl -in ../scripts/alt_edit.drn
../drakon_gen.tcl -in nogoto_src.drn
