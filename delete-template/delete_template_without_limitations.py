#!/usr/bin/env python
# -*- coding: utf-8 -*-

# This script deletes templates. Provide accession of a template which needs to be deleted.
# This script is a temporary solution and may damage studies and delete default template.

# Before template deletion all the studies which have this template set should be manually changed:
# other template which is not going to be deleted should be applied.

# See the full instruction at:
# https://genestack.atlassian.net/wiki/spaces/ODMP/pages/1236926591/How+to+delete+a+template
from __future__ import print_function, unicode_literals

import re

from genestack_client import GenestackServerException
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
        print(colored("Success", GREEN))
    except GenestackServerException as e:
        p = re.compile('File .* not found')
        result = p.search(e.message)
        if result is not None:
            print(colored("Template with accession %s does not exist" % template_accession,
                         RED))
        else:
            print(colored(e, RED))


if __name__ == "__main__":
    main()
