# -*- coding: utf-8 -*-
#$: << File.dirname(__FILE__) + '/../lib'

require 'rubygems' # for 1.8.*

require 'coveralls'
Coveralls.wear!

require 'bundler'
Bundler.setup
Bundler.require(:default,:test)

require 'test/unit'

base_dir = File.expand_path(File.dirname(__FILE__))
$: << base_dir + '/../lib'
# main.rbはコールしない
load base_dir + '/../lib/log_checker/base.rb'

