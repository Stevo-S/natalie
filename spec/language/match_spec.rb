require_relative '../spec_helper'
require_relative 'fixtures/match_operators'

describe "The !~ operator" do
  before :each do
    @obj = OperatorImplementor.new
  end

  it "evaluates as a call to !~" do
    expected = "hello world"

    opval = (@obj !~ expected)
    methodval = @obj.send(:"!~", expected)

    opval.should == expected
    methodval.should == expected
  end
end

describe "The =~ operator" do
  before :each do
    @impl = OperatorImplementor.new
  end

  it "calls the =~ method" do
    expected = "hello world"

    opval = (@obj =~ expected)
    methodval = @obj.send(:"=~", expected)

    opval.should == expected
    methodval.should == expected
  end
end

describe "The =~ operator with named captures" do
  before :each do
    @regexp = /(?<matched>foo)(?<unmatched>bar)?/
    @string = "foofoo"
  end

  describe "on syntax of /regexp/ =~ string_variable" do
    it "sets local variables by the captured pairs" do
      /(?<matched>foo)(?<unmatched>bar)?/ =~ @string
      NATFIXME 'Implement local_variables', exception: NoMethodError, message: /undefined method [`']local_variables' for main/ do
        local_variables.should == [:matched, :unmatched]
      end
      matched.should == "foo"
      unmatched.should == nil
    end
  end

  describe "on syntax of 'string_literal' =~ /regexp/" do
    it "does not set local variables" do
      'string literal' =~ /(?<matched>str)(?<unmatched>lit)?/
      NATFIXME 'Implement local_variables', exception: NoMethodError, message: /undefined method [`']local_variables' for main/ do
        local_variables.should == []
      end
    end
  end

  describe "on syntax of string_variable =~ /regexp/" do
    it "does not set local variables" do
      @string =~ /(?<matched>foo)(?<unmatched>bar)?/
      NATFIXME 'Implement local_variables', exception: NoMethodError, message: /undefined method [`']local_variables' for main/ do
        local_variables.should == []
      end
    end
  end

  describe "on syntax of regexp_variable =~ string_variable" do
    it "does not set local variables" do
      @regexp =~ @string
      NATFIXME 'Implement local_variables', exception: NoMethodError, message: /undefined method [`']local_variables' for main/ do
        local_variables.should == []
      end
    end
  end

  describe "on the method calling" do
    it "does not set local variables" do
      @regexp.=~(@string)
      NATFIXME 'Implement local_variables', exception: NoMethodError, message: /undefined method [`']local_variables' for main/ do
        local_variables.should == []

        @regexp.send :=~, @string
        local_variables.should == []
      end
    end
  end
end
