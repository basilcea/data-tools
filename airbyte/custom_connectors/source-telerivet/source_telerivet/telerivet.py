from typing import cast, Any, Dict, Iterable
import requests
import requests.exceptions


TELERIVET_TIMEOUT = 30


class TelerivetError(Exception):
    """Telerivet network connection errors"""


class TelerivetProject:
    def __init__(self, api_key: str, project_key: str) -> None:
        self.api_key = api_key
        self.project_key = project_key

    def get_tables_count(self) -> int:
        response = requests.get(
            f"https://api.telerivet.com/v1/projects/{self.project_key}/tables",
            params={"count": 1},
            auth=requests.auth.HTTPBasicAuth(self.api_key, ""),
            timeout=TELERIVET_TIMEOUT,
        )

        if response.status_code == 401:
            raise TelerivetError(f"Invalid username or password: {response.text}")
        if response.status_code != 200:
            raise TelerivetError(
                f"Could not reach Telerivet: {response.status_code} - {response.text}",
            )

        return cast(int, response.json().get("count"))

    def get_tables(self) -> Iterable[Dict[str, Any]]:
        url = f"https://api.telerivet.com/v1/projects/{self.project_key}/tables"
        auth = requests.auth.HTTPBasicAuth(self.api_key, "")
        response = requests.get(
            url,
            {"page_size": 50},
            auth=auth,
            timeout=TELERIVET_TIMEOUT,
        )

        while True:
            if response.status_code != 200:
                raise TelerivetError(
                    f"Could not reach Telerivet: {response.status_code} - {response.text}",
                )

            response_body = response.json()
            for table in response_body.get("data", []):
                yield table

            marker = response_body.get("next_marker")
            if not marker:
                return

            response = requests.get(
                url,
                {"page_size": 50, "marker": marker},
                auth=auth,
                timeout=TELERIVET_TIMEOUT,
            )
