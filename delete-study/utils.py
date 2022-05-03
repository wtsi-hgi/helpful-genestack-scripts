#!/usr/bin/env python2.7
# -*- coding: utf-8 -*-

#
# Copyright (c) 2011-2020 Genestack Limited
# All Rights Reserved
# THIS IS UNPUBLISHED PROPRIETARY SOURCE CODE OF GENESTACK LIMITED
# The copyright notice above does not evidence any
# actual or intended publication of such source code.

import sys


BLUE = 34
GREEN = 32
RED = 31


def colored(text, color):
    if sys.platform == 'win32' or not sys.stdout.isatty():
        return text
    return '\033[%dm%s\033[0m' % (color, text)
