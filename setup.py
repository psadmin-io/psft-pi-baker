from setuptools import setup, find_packages

with open('README.md') as readme_file:
    README = readme_file.read()

with open('HISTORY.md') as history_file:
    HISTORY = history_file.read()

setup_args = dict(
    name='psft-baker',
    version='0.0.1',
    description='PeopleTools deployment helper. Bake PIs, Tools deployments, and more!',
    long_description_content_type="text/markdown",
    long_description=README + '\n\n' + HISTORY,
    license='MIT',
    packages=find_packages(),
    author='psadmin.io',
    author_email='info@psadmin.io',
    keywords=['PeopleSoft', 'PeopleTools'],
    url='https://github.com/psadmin-io/psft-pi-baker',
    download_url='https://pypi.org/project/psft-baker/' # TODO
)

install_requires = [
    'py-make'
]

if __name__ == '__main__':
    setup(**setup_args, install_requires=install_requires) # include_package_data=True,
