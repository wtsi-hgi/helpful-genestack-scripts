#!/usr/bin/env python
# -*- coding: utf-8 -*-

# This script deletes studies. Provide study accession of a study which needs to be deleted.

# See the full instruction at:
# https://genestack.atlassian.net/wiki/spaces/ODMP/pages/1225818141/How+to+delete+a+study
from __future__ import print_function, unicode_literals

import re

from genestack_client import GenestackServerException
from genestack_client.utils import make_connection_parser, get_connection

from utils import colored, GREEN, RED


def main():
    parser = make_connection_parser()
    group = parser.add_argument_group('required arguments')
    group.add_argument('--study_accession', metavar='<study_accession>',
                       help='accession of a study to delete', required=True)
    args = parser.parse_args()
    connection = get_connection(args)

    study_accession = args.study_accession
    try:
        connection.application('genestack/arvados-importer').invoke('wipeStudy', study_accession)
        print(colored("Success", GREEN))
    except GenestackServerException as e:
        p = re.compile('File .* not found')
        result = p.search(e.message)
        if result is not None:
            print(colored("Study with accession %s does not exist" % study_accession,
                          RED))
        else:
            print(colored(e, RED))


if __name__ == "__main__":
    main()
