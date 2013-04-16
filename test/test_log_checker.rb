# -*- coding: utf-8 -*-

#require File.expand_path(__dir__) + '/test_helper'
require File.expand_path(File.dirname(__FILE__) + '/test_helper')

class Application < LogChecker::Base
end

class TestLogChecker < Test::Unit::TestCase

  def setup
    @klass =  Application
  end

  def teardown
    @klass.clear
  end

  def test_email
    @klass.email do
      @klass.to   'to@example.com'
      @klass.from 'from@example.com'
    end
    assert_equal ['to@example.com'], @klass.email_obj.to
    assert_equal 'from@example.com', @klass.email_obj.from
    assert_equal '127.0.0.1', @klass.email_obj.smtp_ip
    assert_equal 25, @klass.email_obj.smtp_port
    assert_equal '', @klass.email_obj.subject

    # 一旦オブジェクトクリア
    @klass.clear

    @klass.email do
      @klass.to        'to1@example.com', 'to2@example.com'
      @klass.to        'to3@example.com'
      @klass.from      'from@example.com'
      @klass.subject   'subject'
      @klass.smtp_ip   '8.8.8.8'
      @klass.smtp_port 88
    end
    assert_equal (1..3).map{|o|"to#{o}@example.com"}, @klass.email_obj.to
    assert_equal 'from@example.com', @klass.email_obj.from
    assert_equal 'subject', @klass.email_obj.subject
    assert_equal '8.8.8.8', @klass.email_obj.smtp_ip
    assert_equal 88, @klass.email_obj.smtp_port
  end

  def test_add_file
    assert_equal nil, @klass.files,'files must be null at each test'

    @klass.file('/tmp/dummy') do
      @klass.name 'somename1'
    end
    assert_equal 1, @klass.files.size
    @klass.file('/tmp/dummy') do
      @klass.name 'othername1'
    end
    assert_equal 2, @klass.files.size

    # このテスト方法が間違っていないか？の確認
    # teardownで@klass.clearを呼んでいるが糸通の挙動か？
    @klass.clear

    assert_equal nil, @klass.files,'files must be null at each test'

    @klass.file('/tmp/dummy') do
      @klass.name 'somename2'
    end
    assert_equal 1, @klass.files.size
  end

  # DSLのパースがどんな塩梅か？
  def test_dsl_parsing
    @klass.file('/tmp/dummy') do
      @klass.white 'INFO'
    end
    assert_equal 1, @klass.files[0].white.items.size

    @klass.clear
    @klass.file('/tmp/dummy') do
      @klass.white 'INFO',"WARN"
    end
    assert_equal 2, @klass.files[0].white.items.size

    # 一旦オブジェクトクリア
    @klass.clear

    @klass.file('/tmp/dummy') do
      @klass.white 'INFO',"WARN"
      @klass.white 'NOTICE'
      @klass.black 'ERROR'
      @klass.count 'count a', 'a'
      @klass.gcount 'gcount a', 'a'
      @klass.gcount 'gcount a', 'b'
      @klass.sum    'sum a', 'a'
      @klass.sum    'sum a', 'a' # 同値は排除されているか？
      @klass.gsum   'gsum a', /(\d+)/,/hoge/,'999'
      @klass.gsum   'gsum b', /(\d+)/,'99'
    end
    assert_equal 3, @klass.files.first.white.items.size
    assert_equal 1, @klass.files.first.black.items.size
    assert_equal 1, @klass.files.first.counts.size
    assert_equal 1, @klass.files.first.gcounts.size
    assert_equal 2, @klass.files.first.gcounts.first.conditions.size
    assert_equal 1, @klass.files.first.sums.first.conditions.size
    assert_equal 2, @klass.files.first.gsums.size
    assert_equal 3, @klass.files.first.gsums.first.conditions.size

    @klass.file('/tmp/dummy') do
      @klass.white 'INFO',"WARN"
      @klass.black 'NOTICE'
      @klass.black 'ERROR'
    end

    assert_equal 3, @klass.files.first.white.items.size
    assert_equal 1, @klass.files.first.black.items.size
    assert_equal 2, @klass.files.last.white.items.size
    assert_equal 2, @klass.files.last.black.items.size
  end
end
