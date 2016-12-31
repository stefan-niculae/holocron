#! /usr/bin/env python

# TODO switch to python 3.6 and write type hints & f'...' interpolated strings
from flask import Flask, render_template, jsonify, send_from_directory
import processing
app = Flask(__name__)

# when server starts, generate a dataset and initialize a perceptron
dataset = processing.Dataset()
perceptron = processing.Perceptron()


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
    m = dataset.coord_max
    return jsonify({
        'x': {'min': -m, 'max': m},  # a square
        'y': {'min': -m, 'max': m}
    })


@app.route('/points')
def points():
    records = dataset.df.to_dict(orient='records')
    return jsonify(records)


@app.route('/training_history')
def training_history():
    perceptron.train(dataset, keep_history=True)
    return jsonify(perceptron.history)


@app.route('/regen')
def regen():
    dataset.generate()
    perceptron.reset()
    return NO_CONTENT

if __name__ == '__main__':
    app.run(debug=True)
