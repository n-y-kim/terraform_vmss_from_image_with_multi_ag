import requests

class BearerAuth(requests.auth.AuthBase):
    token = None
    def __init__(self, token):
        self.token = token
    def __call__(self, r):
        r.headers["Authorization"] = "Bearer " + self.token
        return r