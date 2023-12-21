'''Bag of various utility functions'''

from typing import Any, Iterable

class NoDefaultValue:
    '''Used to indicate that a configuration parameter has no default value'''

def dig_dict(config: dict[str, Any], path: Iterable, default: Any = NoDefaultValue) -> Any:
    '''Digs into highly nested maps for values

    Example:
        >>> d = {'foo': { 'bar': {'foobar': 1}}}
        >>> d['foo']['bar']['foobar'] == dig_dict(d, ['foo', 'bar', 'foobar'])
        => True
        >>> dig_dict(d, ['foo', 'bar', 'non-existent'], 'my default')
        => 'my default'
        >>> dig_dict(d, ['foo', 'bar', 'non-existent'])
        => ...
        => KeyError('Invalid key: foo.bar.non-existent')
    '''
    value : Any = config

    for index in path:
        if not isinstance(value, dict) or index not in value:
            if default != NoDefaultValue:
                return default

            raise KeyError(f'Invalid key: {".".join(path)}')

        value = value[index]

    return value
