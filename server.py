#! /usr/bin/env python

from flask import Flask
app = Flask(__name__)


@app.route("/")
def hello():
    return "Hello World!"

app.run(debug=True, port=80, host='0.0.0.0')

