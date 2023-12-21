from dataclasses import dataclass
from typing import Optional

import logging

from gql import gql
from datahub.api.graphql.base import BaseApi

from oaf_datahub import utils

logger = logging.getLogger('superset_action')


@dataclass
class Dataset:
    urn : str
    platform : str
    catalog :  str
    schema : str
    name : str
    domain : str


class DatahubClient(BaseApi):
    def __init__(self, url : str, access_token : Optional[str] = None) -> None:
        super().__init__(datahub_host=url, datahub_token=access_token)

    def get_dataset(self, urn : str) -> Dataset:
        '''Fetch dataset from Datahub using it's id/urn'''
        logger.debug('Fetching dataset from datahub: %s', urn)
        query = gql('''
            query dataset($urn: String!) {
                dataset(urn: $urn) {
                    name
                    platform {
                        name
                    }
                    domain {
                        domain {
                            properties {
                                name
                            }
                        }
                    }
                }
            }
        ''')

        result = self.client.execute(query, variable_values={'urn': urn})
        logger.debug('Retrieved data from Datahub: %s', result)

        if 'errors' in result:
            logger.error('Failed to retrieve dataset `%s`: %s', urn, result['errors'])
            raise Exception(f'Failed to fetch dataset `{urn}` from Datahub')

        dataset = result.get('dataset', {})
        catalog, schema, name = dataset.get('name', '..').split('.')

        return Dataset(
            urn=urn,
            platform=utils.dig_dict(dataset, ['platform', 'name'], None),
            catalog=catalog,
            schema=schema,
            name=name,
            domain=utils.dig_dict(dataset, ['domain', 'domain', 'properties', 'name'], None)
        )

    def add_link_to_dataset(self, urn : str, link_url : str, link_label) -> None:
        '''Adds a link to the resource identified by the given urn'''
        logger.debug('Adding link `%s` to dataset `%s`', link_label, urn)
        query = gql('''
            mutation addLink($urn: String!, $linkUrl: String!, $linkLabel: String!) {
                addLink(
                    input: {
                        resourceUrn: $urn,
                        linkUrl: $linkUrl,
                        label: $linkLabel
                    }
                )
            }
        ''')

        result = self.client.execute(query, variable_values={
            'urn': urn,
            'linkUrl': link_url,
            'linkLabel': link_label
        })
        if 'errors' in result:
            logger.error('Failed to create link on dataset in Datahub: %s', result)
            raise Exception('Failed to create link on dataset')
