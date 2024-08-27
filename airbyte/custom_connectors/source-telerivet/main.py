#
# Copyright (c) 2023 Airbyte, Inc., all rights reserved.
#


import sys

from airbyte_cdk.entrypoint import launch
from source_telerivet import SourceTelerivet

if __name__ == "__main__":
    source = SourceTelerivet()
    launch(source, sys.argv[1:])
