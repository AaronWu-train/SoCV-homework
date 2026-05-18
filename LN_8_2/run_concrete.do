cirr vending_machine.v
cirprint -Summary

set system setup
breset 256 20011 50021
bsetorder -file
bconstruct -all

set system vrf
PINITialstate init
PTRansrelation tri tr

PIMAGe -next 1 reach
PIMAGe -next 1 reach
PIMAGe -next 1 reach
PIMAGe -next 1 reach
PIMAGe -next 1 reach
PIMAGe -next 1 reach
PIMAGe -next 1 reach
PIMAGe -next 1 reach
PIMAGe -next 1 reach
PIMAGe -next 1 reach

breport reach

PCHECKProperty -output 16
PCHECKProperty -output 17
PCHECKProperty -output 18
PCHECKProperty -output 19
PCHECKProperty -output 20
PCHECKProperty -output 21