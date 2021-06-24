#!/bin/zsh

zmv '(*)_3clients_2cores_shuffled.json' '$1_3_shuffled.json'
zmv '(*)_6clients_4cores_shuffled.json' '$1_6_shuffled.json'
zmv '(*)_12clients_8cores_shuffled.json' '$1_12_shuffled.json'
zmv '(*)_singlethreaded.json' '$1_1_shuffled.json'
