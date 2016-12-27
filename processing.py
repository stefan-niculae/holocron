"""
https://blog.dbrgn.ch/2013/3/26/perceptrons-in-python/
"""
import numpy as np
import pandas as pd

# random.seed(9999)


class Dataset:
    def __init__(self, coord_max=1, split=.5, n_points=20):
        self.coord_max = coord_max
        m = coord_max * .4
        s = coord_max * .2

        self.A_x, self.A_y, self.A_label = self.generate_for_class(
            center=(-m, -m),
            spread=(s, s),
            label=-1,
            n_points=int(n_points * split))

        self.B_x, self.B_y, self.B_label = self.generate_for_class(
            center=(m, m),
            spread=(s, s),
            label=1,
            n_points=int(n_points * (1 - split)))

        self.df = pd.DataFrame({
            'x': np.append(self.A_x, self.B_x),
            'y': np.append(self.A_y, self.B_y),
            'label': np.append(self.A_label, self.B_label)},
            columns=['x', 'y', 'bias', 'label'])
        self.df['bias'] = 1

    @staticmethod
    def generate_for_class(center, spread, label, n_points):
        xs = np.random.normal(center[1], spread[0], size=n_points)
        ys = np.random.normal(center[0], spread[1], size=n_points)
        labels = [label] * n_points
        return xs, ys, labels

    def __iter__(self):
        # training data
        for i, row in self.df.iterrows():
            point = np.array([row.x, row.y, row.bias])
            yield point, row.label


class Perceptron:
    def __init__(self, dimension=2):
        self.weights = np.random.uniform(-1, 1, size=dimension + 1)  # random init, the last dimension is the bias
        self.history = []

    @staticmethod
    def hardlims(n):  # activation function
        return 1 if n > 0 else -1

    def train(self, dataset, lr=.01, n_epochs=100, force_retrain=False):
        if self.history and not force_retrain:  # already trained
            return

        n_points = len(dataset.df)

        def predict(p):
            return Perceptron.hardlims(self.weights.dot(p))

        for epoch in range(n_epochs):
            # np.random.shuffle(data)  # TODO?
            for point, expected in dataset:
                error = expected - predict(point)
                self.weights += lr * error * point

            misclassified = [point for point, expected in dataset if predict(point) != expected]
            self.history.append({
                'weights': self.weights.tolist(),
                'misclassified': [p.tolist() for p in misclassified]  # for serialization
            })

            accuracy = 1 - len(misclassified) / n_points
            if accuracy == 1:  # classifies everything correctly
                break
