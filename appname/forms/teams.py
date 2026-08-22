from wtforms import SelectField, StringField, validators

from appname.constants import TEAM_MEMBER_ROLES
from appname.forms import BaseForm


class InviteMemberForm(BaseForm):
    email = StringField('Email', validators=[validators.email(), validators.InputRequired()])
    role = SelectField('Role', default='team member',
                       choices=[(r, r.title()) for r in TEAM_MEMBER_ROLES])
