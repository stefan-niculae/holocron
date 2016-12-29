"""
https://blog.dbrgn.ch/2013/3/26/perceptrons-in-python/
"""
import numpy as np
import pandas as pd


class Dataset:
    def __init__(self, coord_max=1, class_split=.5, n_points=20):
        self.coord_max = coord_max
        self.class_split = class_split
        self.n_points = n_points

        self.A_x = self.A_y = self.A_label = None
        self.B_x = self.B_y = self.B_label = None
        self.df = None
        self.generate()

    def generate(self):
        m = self.coord_max * .4  # TODO random centroids for A and B? (but not too close to the edge)
        s = self.coord_max * .2  # TODO random spread for A and B (but not too high compared to edges)

        self.A_x, self.A_y, self.A_label = self.generate_for_class(
            center=(-m, -m),
            spread=(s, s),
            label=-1,
            n_points=int(self.n_points * self.class_split))

        self.B_x, self.B_y, self.B_label = self.generate_for_class(
            center=(m, m),
            spread=(s, s),
            label=1,
            n_points=int(self.n_points * (1 - self.class_split)))

        self.df = pd.DataFrame({
            'x': np.append(self.A_x, self.B_x),
            'y': np.append(self.A_y, self.B_y),
            'label': np.append(self.A_label, self.B_label)},
            columns=['x', 'y', 'bias', 'label'])
        self.df['bias'] = 1

    @staticmethod
    def generate_for_class(center, spread, label, n_points):
        xs = np.random.normal(center[0], spread[0], size=n_points)
        ys = np.random.normal(center[1], spread[1], size=n_points)
        labels = [label] * n_points
        return xs, ys, labels

    def __iter__(self):
        # training data
        for i, row in self.df.iterrows():
            point = np.array([row.x, row.y, row.bias])
            yield point, row.label


class Perceptron:
    def __init__(self, dimension=2):
        self.dimension = dimension
        self.weights = None
        self.history = None

    def reset(self):
        self.weights = None
        self.history = None

    @staticmethod
    def hardlims(n):  # activation function
        return 1 if n > 0 else -1

    def predict(self, point):
        return Perceptron.hardlims(self.weights.dot(point))

    def train(self, dataset, lr=.01, n_epochs=100, keep_history=False):
        if keep_history and self.history:
            return  # don't reset the already present history

        self.weights = np.random.uniform(-1, 1, size=self.dimension + 1)  # random init, the last dimension is the bias
        self.history = []

        for epoch in range(n_epochs):
            # np.random.shuffle(data)  # TODO?
            for point, expected in dataset:
                error = expected - self.predict(point)
                self.weights += lr * error * point

            misclassified = [point for point, expected in dataset if self.predict(point) != expected]
            self.history.append({
                'weights': self.weights.tolist(),
                'misclassified': [p.tolist() for p in misclassified]  # for serialization
            })

            accuracy = 1 - len(misclassified) / dataset.n_points
            if accuracy == 1:  # classifies everything correctly
                break
