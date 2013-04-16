base_dir = File.expand_path(File.dirname(__FILE__))
$: << base_dir + '/../../lib'
load base_dir + '/../../lib/log_checker.rb'

file "/tmp/sample1" do
  name  'test1'
  white 'INFO','INFO1',"INFO2",/\INFO.*TION/
end

file "/tmp/sample2" do
  name 'test2'
end

file "/tmp/sample1" do
  name 'test_replaced_1'
end
