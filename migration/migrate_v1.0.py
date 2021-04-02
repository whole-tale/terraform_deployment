"""Setup a deployment restored from production backup
"""

import base64
import json
import requests
import os
import pathlib
import shutil
import sys
import time
from requests.auth import HTTPBasicAuth


passwd = sys.argv[1]
domain = sys.argv[2]


print(f"Using domain {domain}")
time.sleep(5)

api_url = f"https://girder.{domain}/api/v1"

r = requests.get(
    api_url + "/user/authentication", auth=HTTPBasicAuth("admin", passwd)
)
r.raise_for_status()
headers = {
    "Content-Type": "application/json",
    "Girder-Token": r.json()["authToken"]["token"],
    "Accept": "application/json",
}

print("Creating default assetstore")
r = requests.post(
    api_url + "/assetstore",
    headers=headers,
    params={
        "type": 0,
        "name": "Base",
        "root": "/tmp/data/base",
    },
)

print("Enabling plugins")
plugins = [
    "oauth",
    "gravatar",
    "jobs",
    "worker",
    "globus_handler",
    "virtual_resources",
    "wt_data_manager",
    "wholetale",
    "wt_home_dir",
    "wt_versioning",
]
r = requests.put(
    api_url + "/system/plugins",
    headers=headers,
    params={"plugins": json.dumps(plugins)},
)
r.raise_for_status()

print("Restarting girder to load plugins")
r = requests.put(api_url + "/system/restart", headers=headers)
r.raise_for_status()

# Give girder time to restart
while True:
    print("Waiting for Girder to restart")
    r = requests.get(
        api_url + "/oauth/provider",
        headers=headers,
        params={"redirect": "http://blah.com"},
    )
    if r.status_code == 200:
        break
    time.sleep(2)

print("Setting up Plugin")

settings = [
    {
        "key": "core.cors.allow_origin",
        "value": f"https://dashboard.{domain}",
    },
    {"key": "core.cookie_domain", "value": f".{domain}"},
    {"key": "wthome.homedir_root", "value": "/tmp/data/homes"},
    {"key": "wthome.taledir_root", "value": "/tmp/data/workspaces"},
    {"key": "wtversioning.runs_root", "value": "/tmp/data/runs"},
    {"key": "wtversioning.versions_root", "value": "/tmp/data/versions"},
]

r = requests.put(
    api_url + "/system/setting",
    headers=headers,
    params={"list": json.dumps(settings)}
)
try:
    r.raise_for_status()
except requests.exceptions.HTTPError:
    if r.status_code >= 400 and r.status_code < 500:
        print(f"Request died with {r.status_code}: {r.reason}")
        print(f"Returned: {r.text}")
    raise

print("Restarting girder to update WebDav roots")
r = requests.put(api_url + "/system/restart", headers=headers)
r.raise_for_status()

print("Creating MATLAB and STATA images")

print("Create Jupyter with Matlab image")
i_params = {
    'config': json.dumps({
        'command': (
            'jupyter notebook --no-browser --port {port} --ip=0.0.0.0 '
            '--NotebookApp.token={token} --NotebookApp.base_url=/{base_path} '
            '--NotebookApp.port_retries=0'
        ),
        'environment': [
            'VERSION=R2020b'
        ],
        'memLimit': '2048m',
        'port': 8888,
        'targetMount': '/home/jovyan/work',
        'urlPath': 'lab?token={token}',
        'buildpack': 'MatlabBuildPack',
        'user': 'jovyan'
    }),
    'icon': (
        'https://upload.wikimedia.org/wikipedia/commons/thumb/2/21/'
        'Matlab_Logo.png/267px-Matlab_Logo.png'
    ),
    'iframe': True,
    'name': 'MATLAB (Jupyter Kernel)',
    'public': True
}
r = requests.post(api_url + '/image', headers=headers,
                  params=i_params)
r.raise_for_status()
image = r.json()

print('Create Matlab Xpra image')
i_params = {
    'config': json.dumps({
        'command': (
            'xpra start --bind-tcp=0.0.0.0:10000 --html=on --daemon=no --exit-with-children=no --start-after-connect="matlab -desktop"'
        ),
        'environment': [
            'VERSION=R2020b'
        ],
        'memLimit': '2048m',
        'port': 10000,
        'targetMount': '/home/jovyan/work',
        'urlPath': '/',
        'buildpack': 'MatlabBuildPack',
        'user': 'jovyan'
    }),
    'icon': (
        'https://upload.wikimedia.org/wikipedia/commons/thumb/2/21/'
        'Matlab_Logo.png/267px-Matlab_Logo.png'
    ),
    'iframe': True,
    'name': 'MATLAB (Linux Desktop)',
    'public': True
}
r = requests.post(api_url + '/image', headers=headers,
                  params=i_params)
r.raise_for_status()
image = r.json()

print('Create Matlab Web Desktop image')
i_params = {
    'config': json.dumps({
        'command': (
            'matlab-jupyter-app'
        ),
        'environment': [
            'VERSION=R2020b'
        ],
        'memLimit': '2048m',
        'port': 8888,
        'targetMount': '/home/jovyan/work',
        'urlPath': 'matlab/index.html',
        'buildpack': 'MatlabBuildPack',
        'user': 'jovyan',
        'csp': "default-src 'self' *.mathworks.com:*; style-src 'self' 'unsafe-inline' *.mathworks.com:*; script-src 'self' 'unsafe-inline' 'unsafe-eval' *.mathworks.com:*; img-src 'self' *.mathworks.com:* data:; frame-ancestors 'self' *.mathworks.com:* dashboard.local.wholetale.org; frame-src 'self' *.mathworks.com:*; connect-src 'self' *.mathworks.com:* wss://localhost:* wss://127.0.0.1:*"
    }),
    'icon': (
        'https://upload.wikimedia.org/wikipedia/commons/thumb/2/21/'
        'Matlab_Logo.png/267px-Matlab_Logo.png'
    ),
    'iframe': True,
    'name': 'MATLAB (Desktop)',
    'public': True
}
r = requests.post(api_url + '/image', headers=headers,
                  params=i_params)
r.raise_for_status()
image = r.json()

print('Create Jupyter with Stata image')
i_params = {
    'config': json.dumps({
        'command': (
            'jupyter notebook --no-browser --port {port} --ip=0.0.0.0 '
            '--NotebookApp.token={token} --NotebookApp.base_url=/{base_path} '
            '--NotebookApp.port_retries=0'
        ),
        'environment': [
            'VERSION=16'
        ],
        'memLimit': '2048m',
        'port': 8888,
        'targetMount': '/home/jovyan/work',
        'urlPath': 'lab?token={token}',
        'buildpack': 'StataBuildPack',
        'user': 'jovyan'
    }),
    'icon': (
        'https://raw.githubusercontent.com/whole-tale/stata-install/main/stata-square.png'
    ),
    'iframe': True,
    'name': 'STATA (Jupyter)',
    'public': True
}
r = requests.post(api_url + '/image', headers=headers,
                  params=i_params)
r.raise_for_status()
image = r.json()

print('Create Stata Xpra image')
i_params = {
    'config': json.dumps({
        'command': (
            'xpra start --bind-tcp=0.0.0.0:10000 --html=on --daemon=no --exit-with-children=no --start-after-connect=xstata'
        ),
        'environment': [
            'VERSION=16'
        ],
        'memLimit': '2048m',
        'port': 10000,
        'targetMount': '/home/jovyan/work',
        'urlPath': '/',
        'buildpack': 'StataBuildPack',
        'user': 'jovyan'
    }),
    'icon': (
        'https://raw.githubusercontent.com/whole-tale/stata-install/main/stata-square.png'
    ),
    'iframe': True,
    'name': 'STATA (Desktop)',
    'public': True
}
r = requests.post(api_url + '/image', headers=headers,
                  params=i_params)
r.raise_for_status()
image = r.json()

print("DONE!!!")
