#!/bin/bash

COUNTER=100

DIR=$(pwd)"/full/pano/"
for i in $DIR*

do
  NEWNAME="$DIR$COUNTER.jpg"
  mv -- "$i" "$NEWNAME"
  ((COUNTER++))
done

COUNTER=1

for i in $DIR*

do
  NEWNAME="$DIR$COUNTER.jpg"
  mv -- "$i" "$NEWNAME"
  ((COUNTER++))
done

COUNTER=100

DIR=$(pwd)"/full/horizontal/"
for i in $DIR*

do
  NEWNAME="$DIR$COUNTER.jpg"
  mv -- "$i" "$NEWNAME"
  ((COUNTER++))
done

COUNTER=1

for i in $DIR*

do
  NEWNAME="$DIR$COUNTER.jpg"
  mv -- "$i" "$NEWNAME"
  ((COUNTER++))
done

COUNTER=100

DIR=$(pwd)"/full/vertical/"
for i in $DIR*

do
  NEWNAME="$DIR$COUNTER.jpg"
  mv -- "$i" "$NEWNAME"
  ((COUNTER++))
done

COUNTER=1

for i in $DIR*

do
  NEWNAME="$DIR$COUNTER.jpg"
  mv -- "$i" "$NEWNAME"
  ((COUNTER++))
done

cp -r ./full/ ./sized
cp -r ./full/ ./thumb

mogrify -resize 1800x1800 ./sized/vertical/*
mogrify -resize 1800x1800 ./sized/horizontal/*
mogrify -resize 1800x1800 ./thumb/pano/*

mogrify -resize 600x600 ./thumb/vertical/*
mogrify -resize 600x600 ./thumb/horizontal/*

