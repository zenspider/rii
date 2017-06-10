#!/usr/bin/env ruby -w

$: << File.expand_path("~/Work/p4/zss/src/sexp_processor/dev/lib/")
$: << File.expand_path("~/Work/p4/zss/src/ruby_parser/dev/lib/")
$: << File.expand_path("~/Work/p4/zss/src/ruby2ruby/dev/lib/")

require "ruby_parser"
require "sexp_processor"
require "ruby2ruby"
require "pp"

class Doco < MethodBasedSexpProcessor
  attr_accessor :r2r

  def initialize
    super
    self.r2r = Ruby2Ruby.new
  end

  def massage_comment lines, level=2
    prefix = "  " * (level+1)
    s = lines.lines.map { |line| line.sub(/^ *#+ */, "") }.join(prefix).strip
    s unless s.empty?
  end

  def process_class exp
    super do
      name = self.klass_name
      comment = massage_comment exp.comments

      if comment then
        puts "  class %s:\n    %s" % [name, comment]
      else
        puts "  class %s:" % [name]
      end
      puts

      process_until_empty exp
    end
  end

  def process_defn exp
    super do
      args, *_body = exp
      msg = self.method_name[1..-1]
      comment = massage_comment exp.comments

      if comment then
        puts "    def %s %p:\n      %s" % [msg, args, comment]
        puts
      end

      process_until_empty exp
    end
  end
end

rp = RubyParser.for_current_ruby
doco = Doco.new

ARGV.each do |dir|
  Dir["#{dir}/**/*.rb"].sort.each do |path|
    puts path
    doco.process rp.parse File.read(path), path
  end
end
