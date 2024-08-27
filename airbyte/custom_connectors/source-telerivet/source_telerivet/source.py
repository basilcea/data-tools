from datetime import datetime
from typing import Any, List, cast, Mapping

import logging

from airbyte_cdk.models import AirbyteConnectionStatus, Status
from airbyte_cdk.sources import AbstractSource
from airbyte_cdk.sources.streams import Stream
from airbyte_cdk.sources.streams.http.auth import BasicHttpAuthenticator
import requests.exceptions

from .streams import DataTableStream
from .telerivet import TelerivetError, TelerivetProject

TELERIVET_TIMEOUT = 30


class SourceTelerivet(AbstractSource):
    def check_connection(
        self,
        logger: logging.Logger,
        config: Mapping[str, Any],
    ) -> AirbyteConnectionStatus:
        logger.info("Checking Telerivet connection")
        project_key = cast(str, config["project_key"])
        api_key = cast(str, config["api_key"])

        try:
            project = TelerivetProject(api_key=api_key, project_key=project_key)
            if project.get_tables_count() == 0:
                logger.warning("Project %s has no accessible data tables", project_key)
                return AirbyteConnectionStatus(
                    status=Status.FAILED,
                    message="No data tables found (perhaps api_key has no access to data tables)",
                )

            return AirbyteConnectionStatus(status=Status.SUCCEEDED)
        except (TelerivetError, requests.exceptions.HTTPError) as error:
            logger.exception("Error connecting to Telerivet", exc_info=error)
            return AirbyteConnectionStatus(
                status=Status.FAILED,
                message=f"Error communicating with Telerivet: {error}",
            )

    def streams(self, config: Mapping[str, Any]) -> List[Stream]:
        api_key = config["api_key"]
        project_key = config["project_key"]
        project = TelerivetProject(api_key=api_key, project_key=project_key)

        streams: list[Stream] = []
        auth = BasicHttpAuthenticator(username=api_key, password="")
        start_date = datetime.fromisoformat(config.get("start_date", "2006-02-01"))

        for table in project.get_tables():
            stream = DataTableStream(
                project_key=project_key,
                table_key=table["id"],
                table_name=table["name"],
                authenticator=auth,
                start_date=start_date,
            )
            streams.append(stream)

        return streams
