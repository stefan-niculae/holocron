"""
https://blog.dbrgn.ch/2013/3/26/perceptrons-in-python/
"""
import numpy as np
import pandas as pd


pd.options.mode.chained_assignment = None  # default='warn'


label_to_number = {
    'A': -1,
    'B': +1
}


class Dataset:
    def __init__(self, coord_max=1, class_split=.5, test_split=.35, n_points=6):
        self.coord_max = coord_max
        self.class_split = class_split
        self.test_split = test_split
        self.n_points = n_points

        self.A_x = self.A_y = self.A_label = None
        self.B_x = self.B_y = self.B_label = None
        self.df = None
        self.generate()

    def generate(self):
        m = self.coord_max * .35  # TODO random centroids for A and B? (but not too close to the edge)
        s = self.coord_max * .25  # TODO random spread for A and B (but not too high compared to edges)

        A = self.gen(centers=(-m, -m), spreads=(s, s), class_per=self.class_split)
        A.label = 'A'

        B = self.gen(centers=(m, m), spreads=(s, s), class_per=1 - self.class_split)
        B.label = 'B'

        self.df = A.append(B).reset_index(drop=True)

    def gen(self, centers, spreads, class_per):
        n_points = int(self.n_points * class_per)
        df = pd.DataFrame(columns=['x', 'y', 'label', 'set'])

        df.x = np.random.normal(centers[0], spreads[0], size=n_points)
        df.y = np.random.normal(centers[1], spreads[1], size=n_points)

        df.set = 'train'
        df.set[:int(n_points * self.test_split)] = 'test'

        return df

    def data(self, only_from_set=None):
        # training data
        for i, row in self.df.iterrows():
            bias = 1
            point = np.array([row.x, row.y, bias])
            expected = label_to_number[row.label]

            if not only_from_set or row.set == only_from_set:
                yield point, expected


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

    def train(self, dataset, lr=.01, n_epochs=100, keep_history=False, min_convergence_epochs=4):
        if keep_history and self.history:
            return  # don't reset the already present history

        # TODO best model checkpoint for non-convergence
        while not self.history or len(self.history) < min_convergence_epochs:
            self.history = []
            self.weights = np.random.uniform(-1, 1,                    # random init
                                             size=self.dimension + 1)  # the last dimension is the bias

            for epoch in range(n_epochs):
                # np.random.shuffle(data)  # TODO?
                for point, expected in dataset.data('train'):
                    error = expected - self.predict(point)
                    self.weights += lr * error * point

                misclassified_train = [p for p, exp in dataset.data('train') if self.predict(p) != exp]
                misclassified_test  = [p for p, exp in dataset.data('test')  if self.predict(p) != exp]
                self.history.append({
                    'weights': self.weights.tolist(),
                    'misclassifiedTrain': len(misclassified_train),
                    'misclassifiedTest': len(misclassified_test),
                })

                train_accuracy = 1 - len(misclassified_train) / dataset.n_points
                if train_accuracy == 1:  # classifies everything correctly
                    break
