#!/usr/bin/env python3

# SPDX-FileCopyrightText: 2020 Björn Fiedler <fiedler@sra.uni-hannover.de>
# SPDX-FileCopyrightText: 2023 Gerion Entrup <entrup@sra.uni-hannover.de>
#
# SPDX-License-Identifier: GPL-3.0-or-later

"""Extract the gcc version string from GCC."""

import argparse
import subprocess
import sys
import re

parser = argparse.ArgumentParser(description=sys.modules[__name__].__doc__)
parser.add_argument('gcc', help='GCC binary')
args = parser.parse_args()

output = subprocess.run([args.gcc, "--version"], capture_output=True).stdout
print(re.search(r'(\d+\.\d+\.\d+)', output.split(b'\n')[0].decode('utf-8')).group(0))
