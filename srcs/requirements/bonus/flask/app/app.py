"""A self-contained phishing-awareness "gotcha".

It looks like a breach checker that asks for your password. When you submit,
it does NOT tell you you're safe -- it reveals that typing a password into a
random website is exactly how credential phishing works.

SECURITY NOTE (the whole point of this demo): the submitted value is never
logged, stored, written to disk, or sent anywhere. We only read its length in
memory to make the reveal land, then it is discarded when the request ends.
There is intentionally no database, no file write, and no outbound request.
"""

from flask import Flask, render_template, request

app = Flask(__name__)


@app.route("/", methods=["GET", "POST"])
def index():
    if request.method == "POST":
        # Read the length only, in memory, to personalise the reveal.
        # The value itself is deliberately never kept, logged, or forwarded.
        password = request.form.get("password", "")
        typed_length = len(password)
        del password  # gone — nothing persisted
        return render_template("gotcha.html", typed_length=typed_length)
    return render_template("index.html")


@app.route("/health")
def health():
    return {"status": "ok"}, 200


if __name__ == "__main__":
    import os
    app.run(host="0.0.0.0", port=int(os.environ.get("FLASK_PORT", 8080)))