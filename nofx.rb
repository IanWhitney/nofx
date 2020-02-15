require "rubygems"
require "bundler/setup"
require "thor"
require "date"
require "fileutils"
require "yaml"

class Transaction
  attr_accessor :id, :type, :amount, :name, :memo
  attr_reader :date

  def date=(date_string)
    @date = Date.parse(date_string).strftime("%Y%m%d%H%M%S")
  end
end

class Nofx < Thor
  include Thor::Actions

  desc "debit", "Add a debit"
  method_option :amount, type: :numeric, required: true
  method_option :name, type: :string, required: true
  method_option :date, type: :string, required: false, default: Date.today.strftime("%F")
  method_option :memo, type: :string, required: false
  def debit()
    transaction = _new_transaction_from_options
    transaction.type = 'debit'
    transaction.amount = transaction.amount.abs * -1.00

    t = _transactions << transaction
    File.open("tmp/expenses.yaml", "w") do |f|
      f.print(YAML.dump(t))
    end
  end

  desc "credit", "Add a credit"
  method_option :amount, type: :numeric, required: true
  method_option :name, type: :string, required: true
  method_option :date, type: :string, required: false, default: Date.today.strftime("%F")
  method_option :memo, type: :string, required: false
  def credit()
    transaction = _new_transaction_from_options
    transaction.type = 'credit'
    transaction.amount = transaction.amount.abs

    t = _transactions << transaction
    File.open("tmp/expenses.yaml", "w") do |f|
      f.print(YAML.dump(t))
    end
  end

  desc "write", "create ofx file"
  def write()
    return if _transactions.empty?

    File.open("output/transactions.ofx", "w") do |f|
      header =  <<~EOF
                  <OFX>
                    <BANKMSGSRSV1>
                      <STMTTRNRS>
                        <STMTRS>
                          <BANKACCTFROM></BANKACCTFROM>
                          <BANKTRANLIST>
                EOF

      f.puts header

      _transactions.each do |transaction|
        entry = <<~EOF
                  <STMTTRN>
                    <TRNTYPE>#{transaction.type}
                    <DTPOSTED>#{transaction.date}
                    <TRNAMT>#{transaction.amount}
                    <FITID>#{transaction.id}
                    <NAME>#{transaction.name}
                    #{ "<MEMO>" + transaction.memo if transaction.memo}
                  </STMTTRN>
                EOF
        f.puts entry
      end

      footer =  <<~EOF
                          </BANKTRANLIST>
                        </STMTRS>
                      </STMTTRNRS>
                    </BANKMSGSRSV1>
                  </OFX>"
                EOF
      f.puts footer
    end
  end

  desc "clear", "remove state"
  def clear()
    FileUtils.rm %w(tmp/expenses.yaml output/transactions.ofx), force: true
  end

  no_commands do
    def _transactions
      if File.exists?("tmp/expenses.yaml")
        YAML.load_file("tmp/expenses.yaml")
      else
        []
      end
    end

    def _new_transaction_from_options
      transaction = Transaction.new
      transaction.date = options.date
      transaction.id = transaction.date.to_i + _transactions.count
      transaction.amount = options.amount
      transaction.name = options.name
      transaction.memo = options.memo
      transaction
    end
  end
end

Nofx.start(ARGV)
