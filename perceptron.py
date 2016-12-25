"""
https://blog.dbrgn.ch/2013/3/26/perceptrons-in-python/
"""
# from matplotlib import pyplot as plt
import pandas as pd
from numpy import random, array, append, concatenate
import numpy as np

# random.seed(9999)

# Configs
DIM = 2
COORD_MAX = 1
SPLIT = .5
N_POINTS = 20

m = COORD_MAX * .4
s = COORD_MAX * .2


A_CENTER = -m, -m
A_SPREAD = s, s

B_CENTER = m, m
B_SPREAD = s, s

N_AS = int(N_POINTS * SPLIT)
N_BS = int(N_POINTS * (1 - SPLIT))


def generate_for_class(center, spread, label, n_points):
    xs = random.normal(center[1], spread[0], size=n_points)
    ys = random.normal(center[0], spread[1], size=n_points)
    labels = [label] * n_points
    return xs, ys, labels

generate_A = lambda: generate_for_class(A_CENTER, A_SPREAD, -1, N_AS)
generate_B = lambda: generate_for_class(B_CENTER, B_SPREAD, +1, N_BS)

# def generate_points(n_points=50):
#     m = COORD_MAX * .4
#     s = COORD_MAX * .3
#
#     A_center = -m, -m
#     A_spread = s, s
#
#     B_center = m, m
#     B_spread = s, s
#
#     n_As = int(n_points * SPLIT)
#     n_Bs = int(n_points * (1-SPLIT))
#
#     A_xs, A_ys, A_labels = generate_for_class(A_center, A_spread, -1, n_As)
#     B_xs, B_ys, B_labels = generate_for_class(B_center, B_spread, -1, n_Bs)
#     import pdb; pdb.set_trace()
#
#
#     # blue_points = random.normal(-m, s, size=(n_points // 2, DIM))
#     # red_points  = random.normal( m, s, size=(n_points // 2, DIM))
#     #
#     # inputs = concatenate([blue_points, red_points])
#     # labels = array([-1] * len(blue_points) + [1] * len(red_points))
#
#     return df


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


# def show_learning(history, points, pause_between=.001):
#     fig = plt.figure()
#     fig.show()
#     ax = fig.gca()
#
#     def redraw_line(w):
#         ax.clear()
#         ax.axhline(y=0, color=[.95, .95, .95])
#         ax.axvline(x=0, color=[.95, .95, .95])
#
#         # Plot the input points
#         half_len = len(points) // 2
#         blue_points = points[:half_len]
#         red_points  = points[half_len + 1:]
#         ax.plot(*blue_points.T, 'bo')
#         ax.plot(*red_points.T, 'ro')
#
#         # Plot the line dividing them
#         x = array([-COORD_MAX, COORD_MAX])
#         a, b, c = w
#         y = - (a * x + c) / b
#         ax.plot(x, y, 'green')
#
#         ax.axis([-COORD_MAX, COORD_MAX, -COORD_MAX, COORD_MAX])
#         fig.canvas.draw()
#
#     for epoch, (weights, misclassified) in enumerate(history):
#         redraw_line(weights)
#
#         accuracy = 1 - len(misclassified) / len(points)
#         print('Epoch {}: {:.1%} accuracy ({} errors)'.format(epoch, accuracy, len(misclassified)))
#
#         plt.pause(pause_between)
#
#         if accuracy == 1:
#             print('Converged in', epoch + 1, 'epochs')
#             break
#
#     else:  # no break
#         print('Did not converge in after', epoch + 1, 'epochs')
#
#     input('Press enter key to exit')


def main():
    print('generating points')
    inputs, labels = generate_points()

    print('training')
    history = train(inputs, labels)

    # print('showing history')
    # show_learning(history, inputs)


if __name__ == '__main__':
    main()
