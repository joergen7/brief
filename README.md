# brief
script to create briefing documents and kneeboard pages

# Introduction

# Usage

    ./brief kneeboard.csv

# Example

airbase, Rota Intl   , wpt:5
airbase, Andersen AFB, wpt:7
tanker,  Shell-1-1,    tcn:12Y, com:253.00

# Syntax

The Syntax of a brief script has the form of a CSV table, i.e., it is a collection of records in the form of lines of text. A record comprises at least two comma-separated fields:

- type
- name


The type field must be either `airbase`, `tanker`, `aew`, `atc`, `tacom`, or `waypoint`. The name is a free-form string designating the current object. If the type is `airbase`, and the name designates an existing airfield then the additional parameters are initialized to match the airfield.
