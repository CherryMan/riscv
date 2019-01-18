#!/usr/bin/env python3

from os.path import join, dirname
from vunit.verilog import VUnit

tests_root = dirname(__file__)
src_dir  = join(tests_root, '../src')

vu = VUnit.from_argv()
lib = vu.add_library("lib")
lib.add_source_files(join(tests_root, "tb_*.sv"), include_dirs=[src_dir])

vu.main()
