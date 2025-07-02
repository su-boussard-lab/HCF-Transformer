import torch
import torch.nn as nn


class TabularEmbedding2(nn.Module):
    def __init__(self, feature_num, embedding_dim):
        super(TabularEmbedding, self).__init__()
        # Include one additional embedding for CLS token
        self.embedding = nn.Parameter(torch.Tensor(feature_num + 1, embedding_dim))
        nn.init.xavier_uniform_(self.embedding)
        self.bias = nn.Parameter(torch.zeros(feature_num + 1, embedding_dim))

    def forward(self, x):
        cls = torch.zeros(x.size(0), 1)
        x = torch.cat((cls, x), dim=1)
        x = x.unsqueeze(2)
        x = x * self.embedding + self.bias
        return x


class TabularEmbedding(nn.Module):
    def __init__(self, feature_num, embedding_dim):
        super(TabularEmbedding, self).__init__()
        self.embedding = nn.Parameter(torch.Tensor(feature_num, embedding_dim))
        nn.init.xavier_uniform_(self.embedding)

        self.cls_embedding = nn.Parameter(torch.Tensor(1, embedding_dim))
        nn.init.xavier_uniform_(self.cls_embedding)

    def forward(self, x):
        em = x.unsqueeze(2) * self.embedding
        cls = self.cls_embedding.expand(x.size(0), 1, -1)
        return torch.cat([cls, em], dim=1)


class TabularTransformer2(nn.Module):
    def __init__(self, num_features, d_embedding, n_head, dim_feedforward, num_layers, dropout, num_classes):
        super(TabularTransformer, self).__init__()
        self.embedding = TabularEmbedding(num_features, d_embedding)
        encoder_layer = nn.TransformerEncoderLayer(d_model=d_embedding, nhead=n_head, dim_feedforward=dim_feedforward,
                                                   dropout=dropout, batch_first=True)
        self.transformer_encoder = nn.TransformerEncoder(encoder_layer, num_layers=num_layers)
        self.hidden = nn.Linear(d_embedding + num_features, (d_embedding + num_features) * 2)
        self.fc = nn.Linear((d_embedding + num_features) * 2, num_classes, bias=True)
        self.elu = nn.ELU()
        self.dropout_layer = nn.Dropout(p=dropout)

    def forward(self, x):
        em = self.embedding(x)
        em = self.transformer_encoder(em)
        #em = em.mean(dim=1)
        em = em[:, 0, :]
        em = self.fc(self.elu(self.hidden(torch.cat((em, x), dim=1))))
        # x = self.classifier(x) # Due to using BCEWithLogitsLoss, activation is removed.
        return em


class TabularTransformer(nn.Module):
    def __init__(self, num_features, d_embedding, n_head, dim_feedforward, num_layers, dropout, num_classes):
        super(TabularTransformer, self).__init__()

        self.embedding = TabularEmbedding(num_features, d_embedding)
        encoder_layer = nn.TransformerEncoderLayer(d_model=d_embedding, nhead=n_head, dim_feedforward=dim_feedforward,
                                                   dropout=dropout, batch_first=True)
        self.transformer_encoder = nn.TransformerEncoder(encoder_layer, num_layers=num_layers)
        self.hidden = nn.Linear(d_embedding, d_embedding * 2)
        self.normalization = nn.LayerNorm(d_embedding)
        self.fc = nn.Linear(d_embedding * 2, num_classes, bias=True)
        self.elu = nn.ELU()

    def forward(self, x):
        x = self.embedding(x)
        x = self.transformer_encoder(x)
        x = x[:, 0, :]
        x = self.fc(self.elu(self.hidden(x)))
        # x = self.fc(self.elu(self.hidden(self.normalization(x))))
        return x


# This transformer does not have trainable embeddings. Embeddings are provided by data
class SeqTransformer_first(nn.Module):
    def __init__(self, d_embedding, n_head, dim_feedforward, num_layers, dropout, num_classes):
        super(SeqTransformer, self).__init__()

        encoder_layer = nn.TransformerEncoderLayer(d_model=d_embedding, nhead=n_head, dim_feedforward=dim_feedforward,
                                                   dropout=dropout, batch_first=True)
        self.transformer_encoder = nn.TransformerEncoder(encoder_layer, num_layers=num_layers)
        self.hidden = nn.Linear(d_embedding * 5, d_embedding)
        self.fc = nn.Linear(d_embedding * 5, num_classes, bias=True)
        self.elu = nn.ELU()

    def forward(self, x):
        x = x[:, 6:]
        x = x.view(x.shape[0], 5, 11)
        x = self.transformer_encoder(x)
        x = torch.flatten(x, start_dim=1)
        x = self.fc(x)
        # x = self.fc(self.elu(self.hidden(self.normalization(x))))
        return x

class SeqTransformer_(nn.Module):
    def __init__(self, d_embedding, n_head, dim_feedforward, num_layers, dropout, num_classes):
        super(SeqTransformer, self).__init__()

        encoder_layer = nn.TransformerEncoderLayer(d_model=d_embedding, nhead=n_head, dim_feedforward=dim_feedforward,
                                                   dropout=dropout, batch_first=True)
        self.transformer_encoder = nn.TransformerEncoder(encoder_layer, num_layers=num_layers)
        self.hidden = nn.Linear(d_embedding * 5, d_embedding)
        self.fc = nn.Linear(d_embedding * 5, num_classes * 3, bias=True)
        self.fc2 = nn.Linear(num_classes * 3 + 6, num_classes, bias=True)
        self.elu = nn.ELU()

    def forward(self, x):
        x1 = x[:, 6:]
        x2 = x[:, 0:6]

        x1 = x1.view(x1.shape[0], 5, 11)
        x1 = self.transformer_encoder(x1)
        x1 = torch.flatten(x1, start_dim=1)
        x1 = self.fc(x1)
        x1 = self.elu(x1)
        x3 = torch.cat((x1, x2), dim=1)
        x3 = self.fc2(x3)

        # x = self.fc(self.elu(self.hidden(self.normalization(x))))
        return x3

class SeqTransformer__(nn.Module):
    def __init__(self, d_embedding, n_head, dim_feedforward, num_layers, dropout, num_classes):
        super(SeqTransformer, self).__init__()

        encoder_layer = nn.TransformerEncoderLayer(d_model=d_embedding, nhead=n_head, dim_feedforward=dim_feedforward,
                                                   dropout=dropout, batch_first=True)
        self.transformer_encoder = nn.TransformerEncoder(encoder_layer, num_layers=num_layers)
        self.fc = nn.Linear(d_embedding * 5, num_classes * 3, bias=True)
        self.fc2 = nn.Linear(num_classes * 3 + 6, num_classes, bias=True)
        self.elu = nn.ELU()
        self.norm = nn.LayerNorm(d_embedding * 5)
        self.norm2 = nn.LayerNorm(num_classes * 3 + 6)

    def forward(self, x):
        x1 = x[:, 6:]
        x2 = x[:, 0:6]

        x1 = x1.view(x1.shape[0], 5, 11)
        x1 = self.transformer_encoder(x1)
        x1 = torch.flatten(x1, start_dim=1)
        x1 = x[:, 6:] + x1
        x1 = self.norm(x1)
        x1 = self.fc(x1)
        x1 = self.elu(x1)
        x3 = torch.cat((x1, x2), dim=1)
        x3 = self.norm2(x3)
        x3 = self.fc2(x3)

        # x = self.fc(self.elu(self.hidden(self.normalization(x))))
        return x3

class SeqTransformer(nn.Module):
    def __init__(self, d_embedding, n_head, dim_feedforward, num_layers, dropout, num_classes):
        super(SeqTransformer, self).__init__()

        encoder_layer = nn.TransformerEncoderLayer(d_model=d_embedding, nhead=n_head, dim_feedforward=dim_feedforward,
                                                   dropout=dropout, batch_first=True)
        self.transformer_encoder = nn.TransformerEncoder(encoder_layer, num_layers=num_layers)
        self.fc1 = nn.Linear(d_embedding * 5, num_classes * 5, bias=True)
        self.fc2 = nn.Linear(num_classes * 5 + 19, num_classes * 3, bias=True)
        self.fc3 = nn.Linear(num_classes * 3 + 6, num_classes, bias=True)
        self.elu = nn.ELU()
        self.norm1 = nn.LayerNorm(d_embedding * 5)
        self.norm2 = nn.LayerNorm(num_classes * 5 + 19)
        self.norm3 = nn.LayerNorm(num_classes * 3 + 6)

    def forward(self, x):
        x1 = x[:, 25:]
        x2 = x[:, 6:25]
        x3 = x[:, 0:6]

        x1 = x1.view(x1.shape[0], 5, 11)
        x1 = self.transformer_encoder(x1)
        x1 = torch.flatten(x1, start_dim=1)
        x1 = x[:, 25:] + x1
        x1 = self.norm1(x1)
        x1 = self.fc1(x1)
        x1 = self.elu(x1)
        x2 = torch.cat((x1, x2), dim=1)
        x2 = self.norm2(x2)
        x2 = self.fc2(x2)
        x2 = self.elu(x2)

        x3 = torch.cat((x2, x3), dim=1)
        x3 = self.norm3(x3)
        x3 = self.fc3(x3)

        return x3

class BiLSTM(nn.Module):
    def __init__(self, d_embedding, hidden_size, num_layers, dropout, num_classes):
        super(BiLSTM, self).__init__()

        self.lstm_layer = nn.LSTM(input_size=d_embedding, hidden_size=hidden_size, num_layers=num_layers, dropout=dropout, batch_first=True, bidirectional=True)
        self.fc = nn.Linear(hidden_size * 2, num_classes, bias=True)
        self.elu = nn.ELU()

    def forward(self, x):
        x = x[:, 6:]
        x = x.view(x.shape[0], 5, 11)
        lstm_output, (h_state, c_state) = self.lstm_layer(x)
        # concat the final hidden states from both directions
        bi_h_sate = torch.cat((h_state[0], h_state[1]), dim=1)
        output = self.fc(bi_h_sate)
        return output


class TabularRegression(nn.Module):
    def __init__(self, num_features, num_hidden, num_classes):
        super(TabularRegression, self).__init__()
        self.hidden = nn.Linear(num_features, num_hidden, bias=True)
        self.fc = nn.Linear(num_hidden, num_classes, bias=True)

    def forward(self, x):
        x = self.hidden(x)
        x = self.fc(x)
        return x
