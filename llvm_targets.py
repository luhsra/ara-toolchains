#!/usr/bin/env python3

# SPDX-FileCopyrightText: 2023 Gerion Entrup <entrup@sra.uni-hannover.de>
#
# SPDX-License-Identifier: GPL-3.0-or-later
"""Extract the llvm targets string from GCC."""

import argparse
import subprocess
import sys
import re

parser = argparse.ArgumentParser(description=sys.modules[__name__].__doc__)
parser.add_argument('--llc', required=True, help='LLC binary')
parser.add_argument('--targets', nargs='+', help='wanted targets')
args = parser.parse_args()

output = subprocess.run([args.llc, "--version"],
                        check=True,
                        capture_output=True).stdout.decode('UTF-8')
targets = set([
    x.strip().split(' ')[0]
    for x in output[output.find("Registered Targets:"):].split('\n')[1:]
])
if args.targets is None:
    print("Supported targets:", targets)
elif not set(args.targets) <= targets:
    print(f"ERROR: Wanted LLVM targets {args.targets} are not in the list "
          f"of supported targets: {sorted(targets)}")
    sys.exit(1)
