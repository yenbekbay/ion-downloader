# -*- coding: utf-8 -*-
from setuptools.command import easy_install
import importlib
import pkg_resources

# If pip is not installed, install it
try:
    import pip
except ImportError:
    easy_install.main(['-U','pip'])
finally:
    pkg_resources.require('pip')
    import pip
# Install external packages
packages = ['musicbrainzngs', 'soundcloud', 'mutagen']
for package in packages:
    try:
        importlib.import_module(package)
    except ImportError:
        pip.main(['install', package])