#!/usr/bin/env python
'''
parses stylebot file into pretty print json, ordered, easier diffing

arg1 = infile
arg2 = outfile
'''
import json
import os
import sys

if __name__ == '__main__':
    STYLES = json.load(open(sys.argv[1], 'r'))
    json.dump(STYLES, open('aaa', 'w'), indent=2, sort_keys=True)
    os.rename('aaa', sys.argv[2])
