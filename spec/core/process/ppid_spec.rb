require_relative '../../spec_helper'

describe "Process.ppid" do
  platform_is_not :windows do
    it "returns the process id of the parent of this process" do
      NATFIXME 'Natalie puts an extra process in between for compilation, this will not work by design' do
        ruby_exe("puts Process.ppid").should == "#{Process.pid}\n"
      end
    end
  end
end
