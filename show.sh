#!/bin/sh
d=$1
cat <<EOF| /Applications/gnuplot.app/gnuplot
set title "$d"
plot [][0:255] '$d' u 1:2 w lp t "ax", '$d' u 1:3 w lp t "ay", '$d' u 1:4 w lp t "az"
EOF
