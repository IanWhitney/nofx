# NOFX

Create OFX files. You shouldn't use this.

Why does it exist? Because there's no good way to get an OFX file for your Apple Card. Unless you want to get the monthly file, but that sucks.

## Usage

Create a credit/income transaction

`ruby nofx.rb credit --amount 1000.00 --name employer --memo 'paycheck for writing sweet apps'`

Create a debit transaction

`ruby nofx.rb debit --amount 12.20 --name apple`

Output your OFX file to `output/transactions.ofx`

`ruby nofx.rb write`

Wipe your transactions

`ruby nofx.rb clear`
