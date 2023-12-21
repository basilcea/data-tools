from typing import Any, cast, Optional

import logging

from datahub.metadata.schema_classes import EntityChangeEventClass

from datahub_actions.action.action import Action
from datahub_actions.event.event_envelope import EventEnvelope
from datahub_actions.event.event_registry import ENTITY_CHANGE_EVENT_V1_TYPE
from datahub_actions.pipeline.pipeline_context import PipelineContext

from oaf_datahub import utils
from oaf_datahub.datahub import DatahubClient, Dataset

from .superset import SupersetClient

# Event types this action listens to
VALID_EVENT_TYPES = (ENTITY_CHANGE_EVENT_V1_TYPE,)

logger = logging.getLogger('superset_action')
logger.setLevel(logging.DEBUG)

CONNECTION_PLATFORMS = ('mssql', 'postgres')


class SupersetAction(Action):
    '''Manages datasets in Superset'''

    @classmethod
    def create(cls, config_dict: dict[str, Any], ctx: PipelineContext) -> Action:
        datahub = DatahubClient(
            url=utils.dig_dict(config_dict, ['datahub', 'url']),
            access_token=utils.dig_dict(config_dict, ['datahub', 'access_token'], None)
        )
        superset = SupersetClient(
            url=utils.dig_dict(config_dict, ['superset', 'url']),
            datahub_url=utils.dig_dict(config_dict, ['datahub', 'url']),
            username=utils.dig_dict(config_dict, ['superset', 'username']),
            password=utils.dig_dict(config_dict, ['superset', 'password']),
            provider=utils.dig_dict(config_dict, ['superset', 'provider'], 'db')
        )

        action = cls(ctx, superset=superset, datahub=datahub)

        for connection in utils.dig_dict(config_dict, ['superset', 'connections'], []):
            action.add_connection(
                platform=connection['platform'],
                catalog=connection['catalog'],
                name=connection['name']
            )

        return action

    def __init__(self, ctx: PipelineContext, superset: SupersetClient,
                 datahub: DatahubClient) -> None:
        self.context = ctx
        self.superset = superset
        self.datahub = datahub
        # platform => database => connection_name
        self.connections : dict[str, dict[str, str]] = {
            platform: {} for platform in CONNECTION_PLATFORMS
        }

    def act(self, event: EventEnvelope) -> None:
        try:
            logger.debug('Processing event: %s', event)
            event_type = event.event_type

            if event_type not in VALID_EVENT_TYPES:
                logger.debug('Ignoring unknown event type: %s', event_type)
                return

            content = cast(EntityChangeEventClass, event.event)
            entity_type = content.entityType

            if entity_type != 'dataset':
                logger.debug('Ignoring non dataset event type: %s', event_type)
                return

            dataset = self.datahub.get_dataset(content.entityUrn)
            connection = self.get_connection(dataset)
            if connection is None:
                logger.debug('Ignoring dataset on unknown connection: %s', dataset)
                return

            dataset_url = self.superset.update_dataset(content.operation, connection, dataset)
            if dataset_url is not None:
                self.datahub.add_link_to_dataset(
                    urn=dataset.urn,
                    link_url=dataset_url,
                    link_label='Browse Dataset on Superset'
                )

            logger.debug('Successfully exported dataset: %s', dataset)
        except:
            logger.exception('Action failed... Exiting', exc_info=True)
            raise

    def close(self) -> None:
        pass

    def add_connection(self, platform : str, catalog : str, name : str) -> None:
        '''Register a superset connection'''
        if platform not in CONNECTION_PLATFORMS:
            raise Exception(f'Invalid connection platform: {platform}')

        self.connections[platform][catalog] = name

    def get_connection(self, dataset : Dataset) -> Optional[dict[str, str]]:
        '''Find connection parameters for dataset in superset'''
        platform = dataset.platform.lower()
        if platform not in self.connections:
            logger.debug('Unknown dataset platform: %s', platform)
            return None

        return self.connections[platform][dataset.catalog.lower()]
