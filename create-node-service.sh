# run  before tezos-node identity generate

sudo cp ./services/tezos-node.service /etc/systemd/system/tezos-node.service
sudo systemctl enable tezos-node.service
sudo systemctl start tezos-node.service
