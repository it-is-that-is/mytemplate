from hashids import Hashids


class HashIds:
    def init_app(self, app):
        salt = app.config.get('SECRET_KEY', 'appname-hashids-secret')
        self.hashids = Hashids(min_length=5, salt=salt)

    def encode_id(self, id_number):
        return self.hashids.encode(id_number)

    def decode_id(self, value):
        numbers = self.hashids.decode(value)
        if len(numbers) != 1:
            raise ValueError(f'Could not decode hash {value} into ID')
        return numbers[0]
