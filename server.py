#! /usr/bin/env python

import numpy as np
from flask import Flask, render_template, jsonify
app = Flask(__name__)

# Configs
N_POINTS = 50
# MAX_COORD = 10  # x and y -- it's a square

A_points = np.random.normal(3, size=(N_POINTS // 2, 2))
B_points = np.random.normal(7, size=(N_POINTS // 2, 2))


@app.route('/')
def hello():
    return render_template('home.html', x=100, l=[1, 2, 3])


@app.route('/coords')
def coords():
    return jsonify(
        A=A_points.tolist(),
        B=B_points.tolist()
    )

app.run(debug=True, port=8080, host='0.0.0.0')

