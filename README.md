# Wrnap

[![Gem Version](https://badge.fury.io/rb/wrnap.png)](http://badge.fury.io/rb/wrnap)

A simple gem for facilitating bindings to various RNA CLI packages (namely http://www.tbi.univie.ac.at/~ivo/RNA/). Note that this gem makes no effort to build and install any wrapped packages at install-time, and instead relies on its presence on the host machine. Also includes a lot of utilities surrounding RNA sequence / structure parsing, graphing using R (via RinRuby) and other analysis tools. Used privately as the foundation for much of the research I do at http://bioinformatics.bc.edu/clotelab/

## Installation

Add this line to your application's Gemfile:

    gem 'wrnap'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install wrnap

## Usage

Simple use case:

    > require "wrnap"
    #=> true
    > rna = Wrnap::Package::Fold.run(seq: "CCUCGAGGGGAACCCGAAAGGGACCCGAGAGG")
    #=> #<Wrnap::Fold:0x007f9c48839dc0>
    > rna.structure
    #=> "((((..(((...(((....))).)))..))))"
    > rna.mfe
    #=> -19.7

... now an even easier way ...

    > mfe_rna = RNA("CCUCGAGGGGAACCCGAAAGGGACCCGAGAGG").run(:fold).mfe_rna
    #=> echo CCUCGAGGGGAACCCGAAAGGGACCCGAGAGG | rnafold --noPS
    #=> Total runtime: 0.013 sec.
    #=> #<Wrnap::Rna CCUCGAGGGGAACCCGAAAG... ((((..(((...(((....) [truncated]>

## Contributing

1. Fork it ( https://github.com/[my-github-username]/wrnap/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
