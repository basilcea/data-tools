from datetime import datetime
from functools import lru_cache
from typing import Any, List, MutableMapping, Iterable, Mapping, Optional

from airbyte_cdk.models import SyncMode
from airbyte_cdk.sources.streams import IncrementalMixin
from airbyte_cdk.sources.streams.core import StreamData
from airbyte_cdk.sources.streams.http import HttpStream

import requests


class DataTableStream(HttpStream, IncrementalMixin):
    """Handle to a data table in Telerivet"""

    cursor_field = "time_created"
    primary_key = "id"

    def __init__(
        self,
        project_key: str,
        table_key: str,
        table_name: str,
        start_date: datetime,
        page_size: int = 200,
        **kwargs,
    ) -> None:
        assert table_key is not None
        assert project_key is not None

        super().__init__(**kwargs)
        self.project_key = project_key
        self.table_key = table_key
        self.page_size = page_size
        self.table_name = table_name
        self.start_timestamp = int(start_date.timestamp())
        self._cursor_value: Optional[int] = None

    @property
    def url_base(self) -> str:
        return f"https://api.telerivet.com/v1/projects/{self.project_key}/tables/{self.table_key}/"

    @property
    def name(self) -> str:
        return self.table_name

    @property
    def state(self) -> MutableMapping[str, int]:
        if self._cursor_value:
            return {self.cursor_field: self._cursor_value}
        else:
            return {self.cursor_field: self.start_timestamp}

    @state.setter
    def state(self, value: MutableMapping[str, int]):
        self._cursor_value = value[self.cursor_field]

    def path(
        self,
        *,
        stream_state: Optional[Mapping[str, Any]] = None,
        stream_slice: Optional[Mapping[str, Any]] = None,
        next_page_token: Optional[Mapping[str, Any]] = None,
    ) -> str:
        return "rows"

    def next_page_token(self, response: requests.Response) -> Optional[Mapping[str, Any]]:
        body = response.json()
        next_marker = body.get("next_marker")
        if next_marker is None:
            return None

        return {"marker": body["next_marker"]}

    def request_params(
        self,
        stream_state: Optional[Mapping[str, Any]],
        stream_slice: Optional[Mapping[str, Any]] = None,
        next_page_token: Optional[Mapping[str, Any]] = None,
    ) -> MutableMapping[str, Any]:
        params = {"page_size": self.page_size}
        if next_page_token is None:
            return params

        params["marker"] = next_page_token["marker"]
        if stream_state:
            params["time_created[min]"] = stream_state[self.cursor_field]

        return params

    def parse_response(
        self,
        response: requests.Response,
        *,
        stream_state: Mapping[str, Any],
        stream_slice: Optional[Mapping[str, Any]] = None,
        next_page_token: Optional[Mapping[str, Any]] = None,
    ) -> Iterable[Mapping[str, Any]]:
        return response.json().get("data", [])

    def read_records(
        self,
        sync_mode: SyncMode,
        cursor_field: Optional[List[str]] = None,
        stream_slice: Optional[Mapping[str, Any]] = None,
        stream_state: Optional[Mapping[str, Any]] = None,
    ) -> Iterable[StreamData]:
        records = super().read_records(
            sync_mode,
            cursor_field,
            stream_slice,
            stream_state,
        )
        for record in records:
            if self._cursor_value:
                self._cursor_value = max(record[self.cursor_field], self._cursor_value)

            yield record

    @lru_cache
    def get_json_schema(self) -> Mapping[str, Any]:
        return {
            "$schema": "http://json-schema.org/draft-07/schema#",
            "type": "object",
            "properties": {
                "id": {"type": "string"},
                "from_number": {"type": "string"},
                "to_number": {"type": "string"},
                "time_created": {"type": "number"},
                "time_updated": {"type": "number"},
                "vars": {"type": "string"},
            },
        }
