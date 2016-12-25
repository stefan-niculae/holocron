#! /usr/bin/env python

import numpy as np
from flask import Flask, render_template, jsonify, send_from_directory
import perceptron
app = Flask(__name__)


# additional static path for npm
@app.route('/npm/<path:filename>')
def npm(filename):
    return send_from_directory('node_modules', filename)


# Constants
NO_CONTENT = ('', 204)


@app.route('/')
def home():
    return render_template('home.html')


@app.route('/bounds')
def bounds():
    M = perceptron.COORD_MAX * 1  # TODO more elegant
    return jsonify({
        'x': {'min': -M, 'max': M},  # a square
        'y': {'min': -M, 'max': M}
    })


@app.route('/points')
def points():
    A_x, A_y, A_label = perceptron.generate_A()
    B_x, B_y, B_label = perceptron.generate_B()

    return jsonify({
        'A': {
            'x': A_x.tolist(),
            'y': A_y.tolist()
        },
        'B': {
            'x': B_x.tolist(),
            'y': B_y.tolist()
        },
    })


@app.route('/regen')
def regen():
    # generate_dataset()
    return NO_CONTENT

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0')

