#!/usr/bin/env ruby -w

$: << File.expand_path("~/Work/p4/zss/src/sexp_processor/dev/lib/")
$: << File.expand_path("~/Work/p4/zss/src/ruby_parser/dev/lib/")
$: << File.expand_path("~/Work/p4/zss/src/ruby2ruby/dev/lib/")

require "ruby_parser"
require "sexp_processor"
require "ruby2ruby"
require "pp"

class Doco < MethodBasedSexpProcessor
  Klass = Struct.new(:name, :superclass, :comment, :methods) do
    def << meth
      self.methods[meth.name] = meth
    end
  end
  Method = Struct.new(:name, :args, :comment)

  attr_accessor :klasses
  attr_accessor :methods
  attr_accessor :r2r

  def initialize
    super
    self.r2r = Ruby2Ruby.new
    self.klasses = Hash.new { |h,k| h[k] = Klass.new(k, :unknown, :unknown, {}) }
    self.methods = {}
  end

  def massage_comment lines, level=2
    prefix = "  " * (level+1)
    s = lines.lines.map { |line| line.sub(/^ *#+ */, "") }.join(prefix).strip
    prefix+s unless s.empty?
  end

  def process_class exp
    super do
      superklass = exp.first
      name = self.klass_name
      comment = massage_comment exp.comments, 1

      klasses[name] = Klass.new(name, superklass, comment, {})

      process_until_empty exp
    end
  end

  def process_defn exp
    super do
      args, *_body = exp
      msg = self.method_name[1..-1]
      comment = massage_comment exp.comments

      klasses[klass_name] << Method.new(msg, args, comment)

      process_until_empty exp
    end
  end

  def generate
    klasses.each do |k,v|
      if v.comment then
        puts "  class %s:\n%s" % [v.name, v.comment]
      else
        puts "  class %s:" % [v.name]
      end
      puts

      v.methods.each do |_, meth|
        if meth.comment then
          puts "    def %s %p:\n%s" % [meth.name, meth.args, meth.comment]
          puts
        end
      end
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

doco.generate
