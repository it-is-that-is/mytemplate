from wtforms import FileField, TextAreaField, validators

from appname.forms import BaseForm


class FileForm(BaseForm):
    description = TextAreaField('Description')
    attachment = FileField('Attachment', validators=[validators.InputRequired()])
