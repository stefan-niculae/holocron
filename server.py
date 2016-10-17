#! /usr/bin/env python

import numpy as np
from flask import Flask, render_template, jsonify
app = Flask(__name__)


# Constants
NO_CONTENT = ('', 204)

# Configs
N_POINTS = 50
# MAX_COORD = 10  # x and y -- it's a square

A_points = []
B_points = []


def generate_dataset():
    def generate_points(around, points_percentage=.5, dimensions=2):
        n_points = int(N_POINTS * points_percentage)
        return np.random.normal(around, size=(n_points, dimensions))

    global A_points, B_points
    A_points = generate_points(around=3)
    B_points = generate_points(around=7)

generate_dataset()


@app.route('/')
def hello():
    return render_template('home.html', x=100, l=[1, 2, 3])


@app.route('/coords')
def coords():
    return jsonify(
        A=A_points.tolist(),
        B=B_points.tolist()
    )


@app.route('/regen')
def regen():
    generate_dataset()
    return NO_CONTENT

#app.run(debug=True, port=8080, host='0.0.0.0')
if __name__ == '__main__':
    app.run(debug=True)

