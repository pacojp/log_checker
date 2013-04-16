#require 'log_checker/base'

module LogChecker
  class Application < Base
    require 'optparse'
    OptionParser.new { |op|
      op.on('-c','--check-dsl', 'check DSL only') { self.is_check = true }
      op.on('-t','--test', 'parse only 1M of each files') { self.is_test = true }
      op.on('-a','--all',  'parse all data(do not touch pointer)') { self.is_all = true }
      op.on('--no-email',  'skip email') { self.no_email = true }
    }.parse!(ARGV.dup)

  end

  at_exit { Application.run! }
end

extend LogChecker::Delegator
