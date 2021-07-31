try:
    from setuptools import setup
except ImportError:
    from distutils.core import setup

config = {
    'description': 'Various tools for image and video manipulation',
    'author': 'Jonathan Bowen',
    'url': 'github.com/jbowen102/mediadapt',
    'download_url': 'github.com/jbowen102/mediadapt.git',
    'author_email': 'ew15dro6k216@opayq.net',
    'version': '',
    'install_requires': ['idevice_media_offload'],
    'packages': [''],
    'scripts': [''],
    'name': 'mediadapt'
}

setup(**config)
