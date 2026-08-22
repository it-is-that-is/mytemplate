from flask_restful import fields, marshal_with

from appname.api import API_VERSION, BaseAPISchema, Resource


class APISchema(BaseAPISchema):
    get_fields = {
        'version': fields.String,
        'url': fields.String,
        'documentation': fields.String,
    }


class APIInfo(Resource):
    schema = APISchema()

    @marshal_with(schema.get_fields)
    def get(self):
        return {
            'version': API_VERSION,
            'url': f'/api/{API_VERSION}/info',
            'documentation': 'Add api_key as a URL query parameter to authenticate'
        }
