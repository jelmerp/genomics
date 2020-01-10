#!/bin/bash
set -e
set -o pipefail
set -u

INFILE=$1

date
echo "Gzipping $INFILE..."

gzip $INFILE

echo "Done."
date