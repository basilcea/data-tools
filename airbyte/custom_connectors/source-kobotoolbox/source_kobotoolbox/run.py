import sys

from airbyte_cdk.entrypoint import launch
from source_kobotoolbox import SourceKobotoolbox

def run():
    source = SourceKobotoolbox()
    launch(source, sys.argv[1:])