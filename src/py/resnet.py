import math
import torch
from torch import nn


class ResNet(nn.Module):
    def __init__(
        self,
        num_features: int = 0,
        size_embedding: int = 256,
        size_hidden: int = 256,
        num_layers: int = 2,
        hidden_factor: int = 1,
        activation=nn.ReLU,
        normalization=nn.BatchNorm1d,
        hidden_dropout=0,
        residual_dropout=0,
        dim_out: int = 1,
        model_type="ResNet"
    ):
        super(ResNet, self).__init__()
        self.name = model_type
        size_embedding = int(size_embedding)
        size_hidden = int(size_hidden)
        num_layers = int(num_layers)
        hidden_factor = int(hidden_factor)
        dim_out = int(dim_out)

        self.num_embedding = NumericalEmbedding(num_features, size_embedding)
        self.first_layer = nn.Linear(size_embedding, size_hidden)
        res_hidden = size_hidden * hidden_factor

        self.layers = nn.ModuleList(
            ResLayer(
                size_hidden,
                res_hidden,
                normalization,
                activation,
                hidden_dropout,
                residual_dropout,
            )
            for _ in range(num_layers)
        )

        self.last_norm = normalization(size_hidden)

        self.head = nn.Linear(size_hidden, dim_out)
        self.size_hidden = size_hidden
        self.dim_out = dim_out

        self.last_act = activation()

    def forward(self, input_x):
        x = self.num_embedding(input_x).mean(dim=1)
        x = self.first_layer(x)
        for layer in self.layers:
            x = layer(x)
        x = self.last_norm(x)
        x = self.last_act(x)
        x = self.head(x)
        x = x.squeeze(-1)
        return x

    def reset_head(self):
        self.head = nn.Linear(self.size_hidden, self.dim_out)


class ResLayer(nn.Module):
    def __init__(
        self,
        size_hidden,
        res_hidden,
        normalization,
        activation,
        hidden_dropout=None,
        residual_dropout=None,
    ):
        super(ResLayer, self).__init__()

        self.norm = normalization(size_hidden)
        self.linear0 = nn.Linear(size_hidden, res_hidden)
        self.linear1 = nn.Linear(res_hidden, size_hidden)

        if hidden_dropout is not None:
            self.hidden_dropout = nn.Dropout(p=hidden_dropout)
        if residual_dropout is not None:
            self.residual_dropout = nn.Dropout(p=residual_dropout)
        self.activation = activation()

    def forward(self, input):
        z = input
        z = self.norm(z)
        z = self.linear0(z)
        z = self.activation(z)
        if self.hidden_dropout is not None:
            z = self.hidden_dropout(z)
        z = self.linear1(z)
        if self.residual_dropout is not None:
            z = self.residual_dropout(z)
        z = z + input
        return z


class NumericalEmbedding(nn.Module):
    def __init__(self, num_embeddings, embedding_dim, bias=True):
        super(NumericalEmbedding, self).__init__()
        self.weight = nn.Parameter(torch.empty(num_embeddings, embedding_dim))
        if bias:
            self.bias = nn.Parameter(torch.empty(num_embeddings, embedding_dim))
        else:
            self.bias = None

        for parameter in [self.weight, self.bias]:
            if parameter is not None:
                nn.init.kaiming_uniform_(parameter, a=math.sqrt(5))

    def forward(self, input):
        x = self.weight[None] * input[..., None]
        if self.bias is not None:
            x = x + self.bias[None]
        return x