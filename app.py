from flask import Flask
from pyteal import *

app = Flask(__name__)

@app.route("/")
def first_encounter():
    return "<p>Hey, can I interest you in some of the latest news?</p>"

