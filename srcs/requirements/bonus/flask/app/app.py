import os

from flask import Flask, render_template, request
from http import HTTPStatus, HTTPMethod

app = Flask(__name__)

DEFAULT_PORT: int = 8080


@app.route("/", methods=[HTTPMethod.GET, HTTPMethod.POST])
def index():
    if request.method == HTTPMethod.POST:
        password = request.form.get("password", "")
        typed_length = len(password)
        return render_template("gotcha.html", typed_length=typed_length)
    return render_template("index.html")


@app.route("/health")
def health():
    return {"status": HTTPStatus.OK.phrase}, HTTPStatus.OK


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("FLASK_PORT", DEFAULT_PORT)))