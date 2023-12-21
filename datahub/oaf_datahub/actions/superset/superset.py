from typing import cast, Callable, Optional
from collections import namedtuple

import json
import logging
import requests

from oaf_datahub.datahub import Dataset

logger = logging.getLogger('superset_action')

REQUEST_TIMEOUT = 10

AuthenticatedRequest = Callable[[requests.Session, dict[str, str]], requests.Response]
Credentials = namedtuple('SupersetCredentials', ('access_token', 'refresh_token'))

class SupersetClient:
    def __init__(self, url, datahub_url : str, username : str, password : str,
                 provider : str='db') -> None:
        self.url = url
        self.datahub_url = datahub_url
        self.session = requests.Session()
        self.access_token, self.refresh_token = self._connect(username, password, provider)

    def update_dataset(self, operation : str, connection : str, dataset : Dataset) -> Optional[str]:
        '''Replicates an operation performed on a Datahub dataset in Superset

        Returns a URL to the dataset in Superset
        '''
        logger.debug('Updating (%s) dataset: %s', operation, dataset)
        match operation.upper():
            case 'ADD' | 'REINSTATE':
                return self._create_dataset(connection, dataset)
            case _:
                logger.warning('Unknown Datahub operation: %s', operation)
                return None

    def _in_session(self, request : AuthenticatedRequest, renew_session : bool=True,
                    with_csrf_token : bool=False) -> requests.Response:
        logger.debug('Executing superset request: %s', request)
        headers = {
            'Content-type': 'application/json',
            'Authorization': f'Bearer {self.access_token}'
        }

        if with_csrf_token:
            headers['X-CSRFToken'] = self._get_csrf_token()

        response = request(self.session, headers)

        if response.status_code == 401 and renew_session:
            logger.debug('Superset session expired, renewing session...')
            self.access_token = self._refresh_session()
            return self._in_session(request, renew_session=False)

        return response

    def _get_csrf_token(self) -> str:
        logger.debug('Fetching CSRF token from Superset')
        response = self._in_session(lambda session, headers : session.get(
            f'{self.url}/api/v1/security/csrf_token/',
            headers=headers,
            timeout=REQUEST_TIMEOUT
        ))

        if response.status_code != 200:
            logger.error('Failed to retrieve CSRF token from superset: %s', response.text)
            raise Exception('Failed to retrieve CSRF token from Superset')

        return response.json()['result']

    def _connect(self, username : str, password : str, provider : str) -> tuple[str, str]:
        logger.debug('Authenticating with Superset at %s', self.url)
        params = {
            'username': username,
            'password': password,
            'provider': provider,
            'refresh': True
        }
        headers = {'Content-type': 'application/json'}

        response = self.session.post(
            f'{self.url}/api/v1/security/login',
            json=params,
            headers=headers,
            timeout=REQUEST_TIMEOUT
        )

        if response.status_code != 200:
            logger.error('Superset login failed: %s', response.text)
            raise Exception('Failed to authenticate with Superset')

        response_body = response.json()

        return Credentials(response_body['access_token'], response_body['refresh_token'])

    def _refresh_session(self) -> str:
        headers = {'Authentication': 'Bearer f{self.refresh_token}'}
        response = self.session.post(
            f'{self.url}/api/v1/security/refresh',
            headers=headers,
            timeout=REQUEST_TIMEOUT
        )

        if response.status_code != 200:
            logger.error('Failed to renew superset session: %s', response.text)
            raise Exception('Failed to renew Superset session')

        response_body = response.json()

        return response_body['access_token']

    def _create_dataset(self, connection : str, dataset : Dataset) -> str:
        logger.debug('Creating dataset in superset(%s): %s', connection, dataset)
        connection_id = self._get_connection_id(connection)
        if connection_id is None:
            raise Exception(f'Could find connection `{connection}` on Superset')

        dataset_id = self._get_dataset_id(connection_id, dataset)
        if dataset_id is not None:
            return f'{self.url}/superset/explore/table/{dataset_id}'

        response = self._in_session(lambda session, headers: session.post(
            f'{self.url}/api/v1/dataset',
            json={
                'database': connection_id,
                'table_name': dataset.name,
                'schema': dataset.schema,
                'external_url': f'{self.datahub_url}/dataset/{dataset.urn}/'
            },
            headers=headers,
            timeout=REQUEST_TIMEOUT
        ), with_csrf_token=True)

        if response.status_code != 201:
            logger.error('Failed to create dataset in Superset: %s', response.text)
            raise Exception(f'Failed to create dataset in Superset: {dataset}')

        response_body = response.json()
        dataset_id = response_body['id']

        return f'{self.url}/superset/explore/table/{dataset_id}'

    def _get_connection_id(self, connection : str) -> Optional[int]:
        response = self._in_session(lambda session, headers: session.get(
            f'{self.url}/api/v1/database',
            params={
                'q': json.dumps({
                    'columns': ['id', 'backend'],
                    'filters': [
                        {'col': 'database_name', 'opr': 'eq', 'value': connection}
                    ]
                })
            },
            headers=headers,
            timeout=REQUEST_TIMEOUT
        ))

        if response.status_code != 200:
            logger.error('Failed to fetch connection ID from Superset: %s', response.text)
            raise Exception('Failed to fetch connection ID from Superset')

        response_body = response.json()
        if not response_body['result']:
            return None

        connection_id = response_body['result'][0]["id"]

        return cast(int, connection_id)

    def _get_dataset_id(self, connection_id : int, dataset : Dataset) -> Optional[int]:
        logger.debug('Fetching ID from superset for dataset: %s', dataset)
        response = self._in_session(lambda session, headers: session.get(
            f'{self.url}/api/v1/dataset',
            params={
                'q': json.dumps({
                    'filters': [
                        {'col': 'table_name', 'opr': 'eq', 'value': dataset.name},
                    ]
                })
            },
            headers=headers,
            timeout=REQUEST_TIMEOUT
        ))

        if response.status_code != 200:
            logger.error('Failed to fetch dataset ID from Superset: %s', response.text)
            raise Exception(f'Failed to fetch dataset ID from Superset: {dataset}')

        response_body = response.json()
        if not response_body['result']:
            return None

        for item in response_body['result']:
            if item['database']['id'] == connection_id and item['schema'] == dataset.schema:
                return cast(int, item['database']['id'])

        return None
