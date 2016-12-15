"""
https://blog.dbrgn.ch/2013/3/26/perceptrons-in-python/
"""
from random import choice
from matplotlib import pyplot as plt
from numpy import random, array, append, concatenate
import numpy as np

# random.seed(9999)

# Configs
DIM = 2
COORD_MAX = 10


def generate_points(n_points=50):
    m = COORD_MAX * .4
    s = COORD_MAX * .3
    blue_points = random.normal(-m, s, size=(n_points // 2, DIM))
    red_points  = random.normal( m, s, size=(n_points // 2, DIM))

    inputs = concatenate([blue_points, red_points])
    labels = array([-1] * len(blue_points) + [1] * len(red_points))

    return inputs, labels


def train(inputs, labels, lr=.01, n_epochs=100):
    inputs = [append(point, 1) for point in inputs]  # add one artificial component for the bias

    weights = random.uniform(-1, 1, size=DIM + 1)  # random init, the last dimension is the bias
    history = []

    hardlims = lambda n: 1 if n > 0 else -1  # activation function
    predict  = lambda p: hardlims(weights.dot(p))

    data = list(zip(inputs, labels))
    for epoch in range(n_epochs):
        random.shuffle(data)
        for point, expected in data:
            error = expected - predict(point)
            weights += lr * error * point

        misclassified = [point for point, expected in data if predict(point) != expected]
        history.append((np.copy(weights), misclassified))

        accuracy = 1 - len(misclassified) / len(inputs)
        if accuracy == 1:  # classifies everything correctly
            break

    return history


def show_learning(history, points, pause_between=.001):
    fig = plt.figure()
    fig.show()
    ax = fig.gca()

    def redraw_line(w):
        ax.clear()
        ax.axhline(y=0, color=[.95, .95, .95])
        ax.axvline(x=0, color=[.95, .95, .95])

        # Plot the input points
        half_len = len(points) // 2
        blue_points = points[:half_len]
        red_points  = points[half_len + 1:]
        ax.plot(*blue_points.T, 'bo')
        ax.plot(*red_points.T, 'ro')

        # Plot the line dividing them
        x = array([-COORD_MAX, COORD_MAX])
        a, b, c = w
        y = - (a * x + c) / b
        ax.plot(x, y, 'green')

        ax.axis([-COORD_MAX, COORD_MAX, -COORD_MAX, COORD_MAX])
        fig.canvas.draw()

    for epoch, (weights, misclassified) in enumerate(history):
        redraw_line(weights)

        accuracy = 1 - len(misclassified) / len(points)
        print('Epoch {}: {:.1%} accuracy ({} errors)'.format(epoch, accuracy, len(misclassified)))

        plt.pause(pause_between)

        if accuracy == 1:
            print('Converged in', epoch + 1, 'epochs')
            break

    else:  # no break
        print('Did not converge in after', epoch + 1, 'epochs')

    input('Press enter key to exit')


def main():
    print('generating points')
    inputs, labels = generate_points()

    print('training')
    history = train(inputs, labels)

    print('showing history')
    show_learning(history, inputs)


if __name__ == '__main__':
    main()
