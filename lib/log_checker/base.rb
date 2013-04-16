module LogChecker
  class Base
    class << self
      attr_accessor :is_check, :is_test, :is_all, :no_email, :files, :current_file, :email_obj

      def debug(st)
        #puts st
      end

      def run!(options = {})
        debug 'start parsing files!!!!'
        debug "@is_check:#{self.is_check}"
        debug "@is_test:#{self.is_test}"
        debug "@is_all:#{self.is_all}"
        debug "@is_no_email:#{self.no_email}"
        if self.is_check
          debug "# TODO puts just dump information"
          return
        end
        self.files.each do |file|
          debug '=' * 20
          debug file.dump
        end
      end

      # テスト用
      # テストなのか？本番なのか？の切り分けが
      # めんどくさいのでこんな逃げで
      def clear
        self.files     = nil
        self.email_obj = nil
      end

      def email
        self.email_obj ||= Email.new
        yield
      end

      def to(*args)
        args.each do |to|
          self.email_obj.to << to
        end
      end

      def from(from)
        self.email_obj.from = from
      end

      def subject(subject)
        self.email_obj.subject = subject
      end

      def smtp_ip(smtp_ip)
        self.email_obj.smtp_ip = smtp_ip
      end

      def smtp_port(smtp_port)
        self.email_obj.smtp_port = smtp_port
      end

      def file(path)
        debug "file called with(#{path})"
        self.files ||= []
        raise 'mnh' if self.current_file
        debug "start to set file"

        self.current_file = LogChecker::File.new(path)
        yield
        self.files << self.current_file
        self.current_file = nil
      end

      def name(_name)
        self.current_file.name = _name
      end

      def white(*args)
        args.each do |item|
          self.current_file.white.items << item
        end
      end

      def black(*args)
        args.each do |item|
          self.current_file.black.items << item
        end
      end

      def count(name,*args)
        summary_proxy(:count,name,*args)
      end

      def gcount(name,*args)
        summary_proxy(:gcount,name,*args)
      end

      def sum(name,*args)
        summary_proxy(:sum,name,*args)
      end

      def gsum(name,*args)
        summary_proxy(:gsum,name,*args)
      end

      private

      def summary_proxy(type,name,*args)
        unless Array === args
          args = [args]
        end
        self.current_file.summaries.add(type,name,args)
      end
    end
  end

  class Email
    attr_accessor :to, :from, :subject, :smtp_ip, :smtp_port

    def initialize
      self.to        = []
      self.smtp_ip   = '127.0.0.1'
      self.smtp_port = 25
      self.subject   = ''
    end
  end

  class SummaryItem
    attr_accessor :type, :name, :conditions, :result

    def initialize(type,name)
      self.type       = type
      self.name       = name
      self.conditions = []
      self.result     = 0.0
    end

    def add(*args)
      self.conditions.concat(*args)
      self.conditions.uniq!
    end
  end

  class SummaryList
    include Enumerable

    attr_accessor :items

    def initialize
      self.items = []
    end

    def each
      self.items.each do |item|
        yield item
      end
    end

    def size
      self.items.size
    end

    def add(type, name, *args)
      cnd = items.select{ |o| o.type == type && o.name == name}.first
      unless cnd
        cnd = SummaryItem.new(type,name)
        items << cnd
      end
      cnd.add(*args)
    end
  end

  class File
    attr_accessor :path, :name,
      :white, :black, :summaries

    def initialize(path)
      self.path    = path
      self.white   = White.new
      self.black   = Black.new
      self.summaries = SummaryList.new
    end

    def counts
      self.summaries.select{|o|o.type == :count}
    end

    def gcounts
      self.summaries.select{|o|o.type == :gcount}
    end

    def sums
      self.summaries.select{|o|o.type == :sum}
    end

    def gsums
      self.summaries.select{|o|o.type == :gsum}
    end

    def dump
      "path:  #{path}\n" +
      "name:  #{name}\n" +
      "white: #{white.dump}\n" +
      "black: #{black.dump}\n"
    end
  end

  module BlackOrWhite
    attr_accessor :items

    def initialize
      self.items = []
    end

    def hit?(line)
      raise 'must impre'
    end

    def dump
      items.join(",")
    end
  end

  class White
    include BlackOrWhite
  end

  class Black
    include BlackOrWhite
  end

  class Application < Base
  end

  module Delegator
    def self.delegate(*methods)
      methods.each do |method_name|
        define_method(method_name) do |*args, &block|
          return super(*args, &block) if respond_to? method_name
          LogChecker::Application.send(method_name, *args, &block)
        end
        private method_name
      end
    end

    delegate :email, :to, :from, :subject,
      :file, :name, :black, :white,
      :count, :gcount, :sum, :gsum
  end
end
