#!/usr/bin/env ruby -w

$: << File.expand_path("~/Work/p4/zss/src/sexp_processor/dev/lib/")
$: << File.expand_path("~/Work/p4/zss/src/ruby_parser/dev/lib/")

require "ruby_parser"
require "sexp_processor"
require "pp"

class Doco < MethodBasedSexpProcessor
  def massage_comment lines, level=2
    prefix = "  " * level
    lines.lines.map { |line| line.sub(/^ *#+ */, "") }.join prefix
  end

  def process_class exp
    _, name, _superklass, *_rest = exp
    comment = massage_comment exp.comments
    comment = "\n" if comment.empty?

    puts "class %s:\n%s" % [name, comment]

    super
  end

  def process_defn exp
    _, msg, args, *_body = exp
    comment = massage_comment exp.comments

    puts "  def %s %p:\n%s" % [msg, process(args), comment]

    super
  end
end

rp = RubyParser.for_current_ruby
doco = Doco.new

Dir["lib/**/*.rb"].sort.each do |path|
  doco.process rp.parse File.read path
  puts
end
