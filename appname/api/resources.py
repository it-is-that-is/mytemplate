from flask import redirect, url_for

from appname.api import API_VERSION, api, api_blueprint
from appname.api.info import APIInfo
from appname.api.user import CurrentUserInfo


@api_blueprint.record
def record_params(setup_state):
    """ Load used app configs into local config on registration from
    appname/__init__.py """
    app = setup_state.app
    api_blueprint.config['tz'] = app.config.get('TIMEZONE', 'utc')  # sample config
    api_blueprint.config['debug'] = app.debug

@api_blueprint.route('/')
def home():
    return redirect(url_for('api.apiinfo'))

api.add_resource(APIInfo, f'/{API_VERSION}/info')
api.add_resource(CurrentUserInfo, f'/{API_VERSION}/user/current')
