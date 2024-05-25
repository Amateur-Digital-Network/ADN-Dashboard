#!/usr/bin/env python
###############################################################################
#   Copyright (C) 2024 Bruno Farias, CS8ABG <cs8abg@gmail.com>
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software Foundation,
#   Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
###############################################################################

__author__     = 'Bruno, CS8ABG'
__version__    = '24.05'
__copyright__  = 'Copyright (c) Bruno, CS8ABG'
__license__    = 'GNU GPLv3'
__maintainer__ = 'Bruno, CS8ABG'
__email__      = 'cs8abg@gmail.com'

from logging import getLogger
from pathlib import Path
from logging.config import dictConfig

def create_logger(conf):
    dictConfig({
        'version': 1,
        'disable_existing_loggers': False,
        'formatters': {
            'std_format': {
                'format': '%(asctime)s %(levelname)s %(message)s',
                'datefmt' : '%Y-%m-%d %H:%M:%S'
            }
        },
        'handlers': {
            'console': {
                'class': 'logging.StreamHandler',
                'formatter': 'std_format',
                'level': conf['LOG_LEVEL']
            },
            'file': {
                'class': 'logging.FileHandler',
                'formatter': 'std_format',
                'filename': Path(conf['PATH'], conf['LOG_FILE']),
                'level': conf['LOG_LEVEL']
            }
        },
        'root': {
            'handlers': conf['LOG_HANDLERS'],
            'level': 'NOTSET',
        }
    })

    return getLogger(__name__)


if __name__ == "__main__":
    log_conf = {
        'PATH': './',
        'LOG_FILE': 'dashboard.log',
        'LOG_LEVEL': 'DEBUG',
        'LOG_HANDLERS': [
            'console',
            'file'
        ]
    }

    logger = create_logger(log_conf)
    
    logger.debug('debug')
    logger.info('info')
    logger.warning('warning')
    logger.error("error")

