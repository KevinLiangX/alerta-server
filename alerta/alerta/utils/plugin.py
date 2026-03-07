import logging
from collections import OrderedDict
from typing import TYPE_CHECKING

from flask import Config, Flask
from importlib.metadata import PackageNotFoundError, entry_points

from alerta.plugins import app

LOG = logging.getLogger('alerta.plugins')

if TYPE_CHECKING:
    from typing import Iterable, Tuple  # noqa

    from alerta.models.alert import Alert  # noqa
    from alerta.plugins import PluginBase  # noqa


class Plugins:

    def __init__(self) -> None:
        self.plugins = OrderedDict()  # type: OrderedDict[str, PluginBase]
        self.rules = None  # entry point

        self.config = Config('/')

        app.init_app()  # fake app for plugin config (deprecated)

    def register(self, app: Flask) -> None:
        self.config = app.config

        ep_map = {}
        for ep in entry_points(group='alerta.plugins'):
            LOG.debug(f"Server plugin '{ep.name}' found.")
            ep_map[ep.name] = ep

        for name in self.config['PLUGINS']:
            try:
                plugin = ep_map[name].load()
                if plugin:
                    self.plugins[name] = plugin()
                    LOG.info(f"Server plugin '{name}' loaded.")
            except Exception as e:
                LOG.error(f"Failed to load plugin '{name}': {str(e)}")
        LOG.info(f"All server plugins enabled: {', '.join(self.plugins.keys())}")
        try:
            routing_dist = self.config.get('ROUTING_DIST')
            if not routing_dist:
                raise ImportError('ROUTING_DIST not configured')
            routing_eps = entry_points(group='alerta.routing')
            rules_ep = next((ep for ep in routing_eps if ep.name == 'rules'), None)
            if rules_ep is None:
                raise PackageNotFoundError(routing_dist)
            self.rules = rules_ep.load()  # type: ignore
        except (PackageNotFoundError, ImportError):
            LOG.info('No plugin routing rules found. All plugins will be evaluated.')

    def routing(self, alert: 'Alert') -> 'Tuple[Iterable[PluginBase], Config]':
        try:
            if self.plugins and self.rules:
                try:
                    r = self.rules(alert, self.plugins, config=self.config)
                except TypeError:
                    r = self.rules(alert, self.plugins)

                if isinstance(r, list):
                    return r, self.config
                else:
                    plugins, config = r
                    return plugins, Config('/', {**self.config, **config})

        except Exception as e:
            LOG.warning(f'Plugin routing rules failed: {e}')

        # default when no routing rules defined
        return self.plugins.values(), self.config
