from wtforms import StringField, validators

from appname.forms import BaseForm


class ChangeProfileForm(BaseForm):
    name = StringField('Name', validators=[validators.InputRequired()])
