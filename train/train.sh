#!/bin/bash
for i in *.train.txt; do 
  ../word2vec/bin/word2vec -train $i -output ${i%%train.txt}.word2vec.txt -classes 200
 done
