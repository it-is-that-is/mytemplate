from datetime import datetime as dt

from flask import render_template

from appname import constants
from appname.extensions import token
from appname.mailers import Mailer


class PurchaseReceipt(Mailer):
    TEMPLATE = 'email/purchase_receipt.html'
    DEFAULT_SUBJECT = "Your purchase of MyTemplate Starter"

    def send(self):
        key = f"{self.recipient.email}-{dt.now()}"
        license = token.generate(key, salt=constants.PURCHASE_LICENSE_SALT)
        html_body = render_template(self.TEMPLATE, license=license)
        return self.deliver_now(self.recipient_email, self.subject, html_body)
