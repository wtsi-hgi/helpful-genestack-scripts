#!/usr/bin/env python2.7
# -*- coding: utf-8 -*-

#
# Copyright (c) 2011-2020 Genestack Limited
# All Rights Reserved
# THIS IS UNPUBLISHED PROPRIETARY SOURCE CODE OF GENESTACK LIMITED
# The copyright notice above does not evidence any
# actual or intended publication of such source code.
#

# This script deletes templates. Provide accession of a template which needs to be deleted.
# This script is a temprorary solution and may damage studies and delete default template.

# Before template deletion all the studies which have this template set should be manually changed:
# other template which is not going to be deleted should be applied.

# Done in the scope of https://genestack.atlassian.net/browse/BR-106

# See the full instruction at:
# https://genestack.atlassian.net/wiki/spaces/ODMP/pages/1236926591/How+to+delete+a+template
import re

from genestack_client.utils import make_connection_parser, get_connection
from utils import colored, GREEN, RED


def main():
    parser = make_connection_parser()
    group = parser.add_argument_group('required arguments')
    group.add_argument('--template_accession', metavar='<template_accession>',
                       help='accession of a template to delete', required=True)
    args = parser.parse_args()
    connection = get_connection(args)

    template_accession = args.template_accession
    try:
        connection.application('genestack/arvados-importer').invoke('wipeStudy', template_accession)
        print colored('Success', GREEN)
    except Exception as e:
        p = re.compile('File .* not found')
        result = p.search(e.message)
        if result is not None:
            print colored('Template with accession %s does not exist' % template_accession, RED)
        else:
            print colored(e, RED)


if __name__ == "__main__":
    main()
